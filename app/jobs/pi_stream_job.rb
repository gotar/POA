# frozen_string_literal: true

class PiStreamJob < ApplicationJob
  queue_as :default

  # Retry on temporary failures
  retry_on PiRpcService::TimeoutError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(conversation_id, assistant_message_id, project_id = nil, pi_provider = nil, pi_model = nil)
    @conversation = Conversation.find(conversation_id)
    @assistant_message = Message.find(assistant_message_id)
    @project = project_id ? Project.find(project_id) : @conversation.project

    # Get the last user message
    user_message = @conversation.messages.where(role: "user").order(created_at: :desc).first
    return unless user_message

    # Build prompt with project context
    prompt = build_prompt(user_message.content)

    # Process with pi and stream response
    stream_response(prompt, pi_provider: pi_provider, pi_model: pi_model)
  rescue PiRpcService::Error => e
    Rails.logger.error "Pi RPC error: #{e.message}"
    error_message = format_error_message(e)
    @assistant_message.update(content: error_message)
    broadcast_error("Failed to communicate with AI assistant: #{error_message}")
    broadcast_complete
  rescue StandardError => e
    Rails.logger.error "Unexpected error in PiStreamJob: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    error_message = "An unexpected error occurred. Please try again."
    @assistant_message.update(content: error_message)
    broadcast_error(error_message)
    broadcast_complete
  end

  private

  def build_prompt(user_content)
    # Always include the browser-agent rules so web searches go through agent-browser.
    instructions = BrowserAgentInstructions.text

    # OpenClaw-style: keep a small stable identity/user context as "living docs".
    identity_context = PersonalKnowledgeRecallService.core_context

    return "#{identity_context}\n\n---\n\n#{instructions}\n\n---\n\n#{user_content}" unless @project

    context_parts = []

    # Add context notes
    if @project.context_notes.any?
      context_parts << "## Project Context"
      context_parts += @project.context_notes.map(&:to_context_string)
    end

    # Add active todos
    active_todos = @project.todos.active.by_position
    if active_todos.any?
      context_parts << "## Active TODOs"
      context_parts += active_todos.map { |t| "- [#{t.status.upcase}] #{t.content}" }
    end

    # Contextual recall from personal knowledge (topics + MEMORY.md) via QMD.
    recall = PersonalKnowledgeRecallService.recall_for(user_content)

    assembled = []
    assembled << identity_context if identity_context.present?
    assembled << instructions
    assembled << context_parts.join("\n\n") if context_parts.any?
    assembled << recall if recall.present?
    assembled << "User message: #{user_content}"

    assembled.compact.join("\n\n---\n\n")
  end

  def stream_response(prompt, pi_provider:, pi_model:)
    pi = PiRpcService.new(provider: pi_provider, model: pi_model)
    pi.start

    full_text = +""
    metadata = {}
    completed = false

    begin
      pi.prompt(prompt) do |event|
        case event["type"]
        when "extension_ui_request"
          next
        when "message_update"
          assistant_event = event["assistantMessageEvent"]
          next unless assistant_event.is_a?(Hash)

          if assistant_event["type"] == "text_delta"
            delta = assistant_event["delta"].to_s
            next if delta.empty?

            full_text << delta
            @assistant_message.update(content: full_text)
            broadcast_update
          end

          partial = assistant_event["partial"]
          if partial.is_a?(Hash)
            extracted = extract_metadata(partial)
            metadata.merge!(extracted) if extracted.present?
          end
        when "message_end"
          msg = event["message"]
          next unless msg.is_a?(Hash) && msg["role"] == "assistant"

          # Non-streaming fallback: extract text from the final message blocks
          if full_text.empty? && msg["content"].is_a?(Array)
            extracted_text = extract_text_from_content(msg["content"])
            full_text = extracted_text if extracted_text.present?
          end

          metadata.merge!(extract_metadata(msg))
        when "agent_end"
          completed = true

          # Final safety fallback: agent_end includes all messages
          if full_text.blank? && event["messages"].is_a?(Array)
            last_assistant = event["messages"].reverse.find { |m| m.is_a?(Hash) && m["role"] == "assistant" }
            if last_assistant&.dig("content").is_a?(Array)
              extracted_text = extract_text_from_content(last_assistant["content"])
              full_text = extracted_text if extracted_text.present?
              metadata.merge!(extract_metadata(last_assistant))
            end
          end

          @assistant_message.update(content: full_text, metadata: metadata)
          broadcast_complete(metadata)
        end
      end
    ensure
      unless completed
        @assistant_message.update(content: full_text, metadata: metadata)
        broadcast_complete(metadata)
      end

      # Small delay to allow any last buffered events to be processed
      sleep 0.1
      pi.stop rescue nil
    end
  end

  def extract_text_from_content(content)
    return "" unless content.is_a?(Array)

    text_parts = content.filter_map do |block|
      next unless block.is_a?(Hash)
      next if block["type"].to_s == "thinking"

      if block["type"].to_s == "text"
        txt = block["text"].to_s
        txt.presence
      end
    end

    text_parts.join("\n").strip
  end

  def extract_metadata(message)
    return {} unless message.is_a?(Hash)

    metadata = {}

    metadata[:model] = message["model"] if message["model"]
    metadata[:provider] = message["provider"] if message["provider"]
    metadata[:api] = message["api"] if message["api"]

    if message["usage"]
      usage = message["usage"]
      metadata[:usage] = {
        input_tokens: usage["input"],
        output_tokens: usage["output"],
        cache_read_tokens: usage["cacheRead"],
        cache_write_tokens: usage["cacheWrite"],
        total_tokens: usage["total"],
        cost: usage["cost"]
      }
    end

    metadata[:stop_reason] = message["stopReason"] if message["stopReason"]

    metadata
  end

  def broadcast_update
    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: "message_#{@assistant_message.id}",
      partial: "messages/message",
      locals: { message: @assistant_message.reload }
    )
  end

  def broadcast_complete(metadata = {})
    @assistant_message.update(metadata: metadata) if metadata.present?
    broadcast_update

    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: "message_form",
      partial: "messages/form",
      locals: {
        project: @project,
        conversation: @conversation,
        message: @conversation.messages.build(role: "user")
      }
    )
  end

  def format_error_message(error)
    case error
    when PiRpcService::TimeoutError
      "⏰ The AI assistant took too long to respond. Please try again."
    when PiRpcService::ProcessError
      "🔧 AI assistant service is currently unavailable. Please try again."
    else
      "❌ Unable to connect to AI assistant: #{error.message}"
    end
  end

  def broadcast_error(error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: "message_#{@assistant_message.id}",
      partial: "messages/message",
      locals: { message: @assistant_message.reload }
    )

    Turbo::StreamsChannel.broadcast_append_to(
      @conversation,
      target: "messages",
      partial: "shared/error",
      locals: { message: error_message }
    )
  end
end

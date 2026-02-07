# frozen_string_literal: true

class PiStreamJob < ApplicationJob
  queue_as :default

  # Retry on temporary failures
  retry_on PiRpcService::TimeoutError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(conversation_id, assistant_message_id, project_id = nil)
    @conversation = Conversation.find(conversation_id)
    @assistant_message = Message.find(assistant_message_id)
    @project = project_id ? Project.find(project_id) : @conversation.project

    # Get the last user message
    user_message = @conversation.messages.where(role: "user").order(created_at: :desc).first
    return unless user_message

    # Build prompt with project context
    prompt = build_prompt(user_message.content)

    # Process with pi and stream response
    stream_response(prompt)
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
    return user_content unless @project

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

    if context_parts.any?
      "#{context_parts.join("\n\n")}\n\n---\n\nUser message: #{user_content}"
    else
      user_content
    end
  end

  def stream_response(prompt)
    pi = PiRpcService.new
    pi.start

    full_text = ""
    full_thinking = ""
    metadata = {}

    begin
      pi.prompt(prompt) do |event|
        event_type = event["type"]

        # Skip UI requests
        next if event_type == "extension_ui_request"

        case event_type
        when "message_update"
          assistant_event = event["assistantMessageEvent"]
          if assistant_event
            inner_type = assistant_event["type"]

            # Handle text content (visible to user)
            if inner_type == "text_delta"
              delta = assistant_event["delta"]
              if delta && delta.present?
                full_text += delta
                @assistant_message.update(content: full_text)
                broadcast_update
              end
            end

            # Extract metadata from partial message
            if assistant_event["partial"]
              extracted = extract_metadata(assistant_event["partial"])
              metadata.merge!(extracted) if extracted.present?
            end
          end
        when "message_end"
          if event["message"]
            metadata = extract_metadata(event["message"])
          end
          @assistant_message.update(content: full_text)
          broadcast_complete(metadata)
        when "agent_end"
          @assistant_message.update(content: full_text)
          broadcast_complete(metadata)
        end
      end
    ensure
      pi.stop rescue nil
    end
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

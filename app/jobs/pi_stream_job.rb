# frozen_string_literal: true

require "base64"

class PiStreamJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  # Retry on temporary failures
  retry_on PiRpcService::TimeoutError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(conversation_id, assistant_message_id, project_id = nil, pi_provider = nil, pi_model = nil, user_message_id = nil)
    user_message = nil

    @conversation = Conversation.find(conversation_id)
    @assistant_message = Message.find(assistant_message_id)
    @project = project_id ? Project.find(project_id) : @conversation.project

    user_message = if user_message_id.present?
      @conversation.messages.find_by(id: user_message_id, role: "user")
    else
      @conversation.messages.where(role: "user").order(created_at: :desc).first
    end
    return unless user_message

    @current_user_message = user_message

    # User messages are persisted before the job runs, so they are already "sent".
    # We keep `status` only to indicate queueing.
    user_message.update!(status: "done") if user_message.status == "queued"

    @assistant_message.update!(status: "running") if @assistant_message.respond_to?(:status) && @assistant_message.status != "running"

    # Build prompt with project context + conversation history
    prompt = build_prompt(user_message)

    images = build_images_payload(user_message)

    # Process with pi and stream response
    stream_response(prompt, images: images, pi_provider: pi_provider, pi_model: pi_model)
  rescue PiRpcService::Error => e
    Rails.logger.error "Pi RPC error: #{e.message}"
    error_message = format_error_message(e)
    @assistant_message.update(content: error_message, status: "error")
    user_message&.update(status: "error")
    broadcast_user_status_update(user_message)
    broadcast_error("Failed to communicate with AI assistant: #{error_message}")
    broadcast_complete
  rescue StandardError => e
    Rails.logger.error "Unexpected error in PiStreamJob: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    error_message = "❌ An unexpected error occurred. Please try again."
    @assistant_message.update(content: error_message, status: "error")
    user_message&.update(status: "error")
    broadcast_user_status_update(user_message)
    broadcast_error(error_message)
    broadcast_complete
  ensure
    # Ensure conversation processing flag is released and run any queued messages.
    finalize_and_maybe_run_next!(user_message&.id)
  end

  private

  CHAT_HISTORY_MAX_MESSAGES = ENV.fetch("PI_CHAT_HISTORY_MAX_MESSAGES", "20").to_i
  CHAT_HISTORY_MAX_CHARS = ENV.fetch("PI_CHAT_HISTORY_MAX_CHARS", "12000").to_i
  CHAT_HISTORY_PER_MESSAGE_MAX_CHARS = ENV.fetch("PI_CHAT_HISTORY_PER_MESSAGE_MAX_CHARS", "2000").to_i

  def build_prompt(user_message)
    user_content = user_message.content.to_s

    # Always include the browser-agent rules so web searches go through agent-browser.
    instructions = BrowserAgentInstructions.text

    # OpenClaw-style: keep a small stable identity/user context as "living docs".
    identity_context = PersonalKnowledgeRecallService.core_context

    conversation_context = build_conversation_history(before_time: user_message.created_at)

    unless @project
      parts = []
      parts << identity_context if identity_context.present?
      parts << instructions
      parts << "## Conversation context\n\n#{conversation_context}" if conversation_context.present?
      parts << "## User message\n\n#{user_content}"
      return parts.compact.join("\n\n---\n\n")
    end

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

    # If this conversation represents a scheduled job run, include the current
    # scheduled job prompt template so the agent can propose updates.
    if @conversation&.scheduled_job
      sj = @conversation.scheduled_job
      context_parts << "## Scheduled Job Context"
      context_parts << "Name: #{sj.name}"
      context_parts << "Cron: #{sj.cron_expression}"
      context_parts << "Current prompt template:\n```\n#{sj.prompt_template}\n```"
      context_parts << "If the user asks to update the scheduled job prompt template, reply with a code block only:\n```scheduled_job_prompt_template\n<new prompt template>\n```"
    end

    # OpenClaw-style: only load curated living docs (no QMD retrieval during chat).
    recall = PersonalKnowledgeRecallService.memory_context

    assembled = []
    assembled << identity_context if identity_context.present?
    assembled << instructions
    assembled << context_parts.join("\n\n") if context_parts.any?
    assembled << recall if recall.present?
    assembled << "## Conversation context\n\n#{conversation_context}" if conversation_context.present?
    assembled << "## User message\n\n#{user_content}"

    assembled.compact.join("\n\n---\n\n")
  end

  def build_conversation_history(before_time:)
    ConversationCompactionService.context_for_prompt(
      conversation: @conversation,
      before_time: before_time,
      history_max_messages: CHAT_HISTORY_MAX_MESSAGES,
      history_max_chars: CHAT_HISTORY_MAX_CHARS,
      history_per_message_max_chars: CHAT_HISTORY_PER_MESSAGE_MAX_CHARS
    )
  rescue StandardError
    ""
  end

  def stream_response(prompt, images:, pi_provider:, pi_model:)
    full_text = +""
    metadata = {}
    completed = false

    PiRpcPool.with_client(provider: pi_provider, model: pi_model) do |pi|
      begin
        pi.prompt(prompt, images: images) do |event|
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
          when "tool_execution_start"
            upsert_tool_call!(event, status: "running")
            broadcast_tools_update
          when "tool_execution_update"
            upsert_tool_call!(event, status: "running", partial: true)
            broadcast_tools_update
          when "tool_execution_end"
            upsert_tool_call!(event, status: event["isError"] ? "error" : "done", partial: false)
            broadcast_tools_update
          when "agent_end"
            completed = true
            finalize_incomplete_tool_calls!(final_status: "done")
            broadcast_tools_update

            # Final safety fallback: agent_end includes all messages
            if full_text.blank? && event["messages"].is_a?(Array)
              last_assistant = event["messages"].reverse.find { |m| m.is_a?(Hash) && m["role"] == "assistant" }
              if last_assistant&.dig("content").is_a?(Array)
                extracted_text = extract_text_from_content(last_assistant["content"])
                full_text = extracted_text if extracted_text.present?
                metadata.merge!(extract_metadata(last_assistant))
              end
            end

            @assistant_message.update(content: full_text, metadata: metadata, status: "done")
            @current_user_message&.update(status: "done")
            maybe_apply_scheduled_job_prompt_update!(full_text)
            broadcast_complete(metadata)
          end
        end
      ensure
        unless completed
          finalize_incomplete_tool_calls!(final_status: "error", note: "Interrupted (agent stopped before tool finished).")
          broadcast_tools_update

          @assistant_message.update(content: full_text, metadata: metadata, status: "error")
          @current_user_message&.update(status: "error")
          broadcast_user_status_update(@current_user_message)
          maybe_apply_scheduled_job_prompt_update!(full_text)
          broadcast_complete(metadata)
        end

        # Small delay to allow any last buffered events to be processed
        sleep 0.1
      end
    end
  end

  MAX_IMAGE_BYTES = (ENV.fetch("PI_MAX_IMAGE_BYTES", "2000000")).to_i
  MAX_IMAGES = (ENV.fetch("PI_MAX_IMAGES_PER_MESSAGE", "2")).to_i

  def build_images_payload(user_message)
    return [] unless user_message.respond_to?(:attachments)

    imgs = user_message.attachments.select(&:image?).first(MAX_IMAGES)
    imgs.filter_map do |att|
      next unless att.file.attached?

      blob = att.file.blob
      next if blob.byte_size.to_i > MAX_IMAGE_BYTES

      data = blob.download
      {
        type: "image",
        data: Base64.strict_encode64(data),
        mimeType: blob.content_type
      }
    rescue StandardError => e
      Rails.logger.debug("PiStreamJob: failed to include image attachment #{att.id}: #{e.message}")
      nil
    end
  end

  def maybe_apply_scheduled_job_prompt_update!(assistant_text)
    sj = @conversation&.scheduled_job
    return unless sj

    tpl = extract_scheduled_job_prompt_template(assistant_text)
    return if tpl.blank?

    # Avoid no-op updates / repeated toasts
    return if tpl.strip == sj.prompt_template.to_s.strip

    sj.update!(prompt_template: tpl)

    Turbo::StreamsChannel.broadcast_append_to(
      @conversation,
      target: "toast-container",
      partial: "shared/toast",
      locals: {
        message: "Scheduled job prompt template updated (#{sj.name})",
        type: :success
      }
    )
  rescue StandardError => e
    Rails.logger.error("PiStreamJob: failed to apply scheduled job prompt update: #{e.class}: #{e.message}")
  end

  def extract_scheduled_job_prompt_template(text)
    t = text.to_s
    m = t.match(/```scheduled_job_prompt_template\s*(.*?)\s*```/m)
    return nil unless m

    m[1].to_s.strip
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

  TOOL_OUTPUT_MAX_BYTES = (ENV.fetch("PI_TOOL_OUTPUT_MAX_BYTES", "30000")).to_i

  def upsert_tool_call!(event, status:, partial: false)
    tool_call_id = event["toolCallId"].to_s
    tool_name = event["toolName"].to_s
    return if tool_call_id.blank? || tool_name.blank?

    tc = @assistant_message.tool_calls.find_or_initialize_by(tool_call_id: tool_call_id)

    tc.tool_name = tool_name
    tc.args = event["args"] if event.key?("args")
    tc.status = status
    tc.is_error = (status == "error")

    tc.started_at ||= Time.current if event["type"].to_s == "tool_execution_start"
    tc.ended_at = Time.current if event["type"].to_s == "tool_execution_end"

    result_key = partial ? "partialResult" : "result"
    if event[result_key].is_a?(Hash)
      text = extract_tool_output_text(event[result_key])
      tc.output_text = truncate_tool_output(text) if text.present?
    end

    tc.save!
  rescue StandardError => e
    Rails.logger.debug("PiStreamJob: failed to upsert tool call: #{e.class}: #{e.message}")
  end

  def extract_tool_output_text(result)
    # result: {"content": [{"type":"text","text":"..."}, ...], "details": {...}}
    content = result["content"]
    return "" unless content.is_a?(Array)

    content.filter_map do |block|
      next unless block.is_a?(Hash)
      next unless block["type"].to_s == "text"

      t = block["text"].to_s
      t.presence
    end.join("")
  end

  def truncate_tool_output(text)
    t = text.to_s
    return t if TOOL_OUTPUT_MAX_BYTES <= 0

    if t.bytesize > TOOL_OUTPUT_MAX_BYTES
      t.byteslice(0, TOOL_OUTPUT_MAX_BYTES) + "\n\n...(truncated)..."
    else
      t
    end
  end

  def finalize_incomplete_tool_calls!(final_status:, note: nil)
    return unless @assistant_message&.respond_to?(:tool_calls)

    running = @assistant_message.tool_calls.where(status: "running")
    return if running.none?

    running.find_each do |tc|
      tc.status = final_status
      tc.is_error = (final_status == "error")
      tc.ended_at ||= Time.current

      if note.present?
        if tc.output_text.present?
          unless tc.output_text.include?(note)
            tc.output_text = truncate_tool_output("#{tc.output_text}\n\n#{note}")
          end
        else
          tc.output_text = truncate_tool_output(note)
        end
      end

      tc.save!
    end
  rescue StandardError => e
    Rails.logger.debug("PiStreamJob: failed to finalize tool calls: #{e.class}: #{e.message}")
  end

  def broadcast_tools_update
    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: "message_#{@assistant_message.id}_tools",
      partial: "messages/tool_calls",
      locals: { message: @assistant_message.reload }
    )
  end

  def broadcast_update
    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: "message_#{@assistant_message.id}",
      partial: "messages/message",
      locals: { message: @assistant_message.reload }
    )
  end

  def broadcast_user_status_update(user_message)
    return unless user_message

    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: dom_id(user_message),
      partial: "messages/message",
      locals: { message: user_message.reload }
    )
  rescue StandardError
    nil
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

  def finalize_and_maybe_run_next!(finished_user_message_id)
    return unless defined?(@conversation) && @conversation.present?

    next_user = nil
    next_assistant = nil

    @conversation.with_lock do
      # Release processing state.
      @conversation.update!(processing: false, processing_started_at: nil)

      next_user = @conversation.messages.where(role: "user", status: "queued").order(:created_at).first
      next unless next_user

      @conversation.update!(processing: true, processing_started_at: Time.current)
      # Remove queued badge now that we are starting to process it.
      next_user.update!(status: "done")
      next_assistant = @conversation.messages.create!(role: "assistant", content: "", status: "running")

      # Enqueue next run after lock is released
    end

    return unless next_user && next_assistant

    # Update the queued user message badge + append a new assistant placeholder.
    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: dom_id(next_user),
      partial: "messages/message",
      locals: { message: next_user.reload }
    )

    Turbo::StreamsChannel.broadcast_append_to(
      @conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: next_assistant }
    )

    PiStreamJob.perform_later(
      @conversation.id,
      next_assistant.id,
      @project&.id,
      @conversation.pi_provider,
      @conversation.pi_model,
      next_user.id
    )
  rescue StandardError => e
    Rails.logger.error("PiStreamJob: finalize failed: #{e.class}: #{e.message}")
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

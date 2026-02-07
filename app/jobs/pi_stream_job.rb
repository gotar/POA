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
    broadcast_complete # Re-enable the form
  rescue StandardError => e
    Rails.logger.error "Unexpected error in PiStreamJob: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    error_message = "An unexpected error occurred. Please try again."
    @assistant_message.update(content: error_message)
    broadcast_error(error_message)
    broadcast_complete # Re-enable the form
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

    full_content = ""
    metadata = {}

    begin
      pi.prompt(prompt) do |event|
        case event["type"]
        when "message_update"
          # Capture metadata from assistant message events
          if event["assistantMessageEvent"] && event["assistantMessageEvent"]["type"] == "done"
            assistant_event = event["assistantMessageEvent"]
            if assistant_event["partial"]
              metadata = extract_metadata_from_message(assistant_event["partial"])
            end
          end

          # Handle text deltas
          assistant_event = event["assistantMessageEvent"]
          if assistant_event && assistant_event["type"] == "text_delta"
            full_content += assistant_event["delta"]
            @assistant_message.update(content: full_content)
            broadcast_update
          end
        when "message_end"
          # Extract metadata from completed message
          if event["message"]
            metadata = extract_metadata_from_message(event["message"])
          end
          @assistant_message.update(content: full_content)
          broadcast_complete(metadata)
        when "agent_end"
          # Final update with metadata
          @assistant_message.update(content: full_content)
          broadcast_complete(metadata)
        end
      end
    ensure
      pi.stop
    end
  end

  def extract_metadata_from_message(message)
    return {} unless message

    metadata = {}

    # Extract model information
    if message["model"]
      metadata[:model] = message["model"]
    end

    if message["provider"]
      metadata[:provider] = message["provider"]
    end

    if message["api"]
      metadata[:api] = message["api"]
    end

    # Extract usage information
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

    # Extract stop reason
    if message["stopReason"]
      metadata[:stop_reason] = message["stopReason"]
    end

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
    # Save metadata to the message
    @assistant_message.update(metadata: metadata) if metadata.present?

    broadcast_update

    # Re-enable input
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
      "🔧 AI assistant service is currently unavailable. Please try again in a moment."
    else
      "❌ Unable to connect to AI assistant: #{error.message}"
    end
  end

  def broadcast_error(error_message)
    # Update the assistant message to show error state
    Turbo::StreamsChannel.broadcast_replace_to(
      @conversation,
      target: "message_#{@assistant_message.id}",
      partial: "messages/message",
      locals: { message: @assistant_message.reload }
    )

    # Also append an error notification
    Turbo::StreamsChannel.broadcast_append_to(
      @conversation,
      target: "messages",
      partial: "shared/error",
      locals: { message: error_message }
    )
  end
end

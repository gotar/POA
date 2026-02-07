# frozen_string_literal: true

class ScheduledJobRunnerJob < ApplicationJob
  queue_as :default

  # Retry on temporary failures
  retry_on PiRpcService::TimeoutError, wait: :exponentially_longer, attempts: 3
  retry_on PiRpcService::ProcessError, wait: 30.seconds, attempts: 2
  discard_on ActiveRecord::RecordNotFound

  def perform(scheduled_job_id)
    scheduled_job = ScheduledJob.find(scheduled_job_id)

    # Skip if job is disabled
    return unless scheduled_job.active?

    # Mark job as running
    scheduled_job.update!(status: "running", last_run_at: Time.current)

    begin
      # Execute the prompt template
      result = execute_prompt_template(scheduled_job)

      # Mark job as completed
      scheduled_job.update!(status: "completed")
      scheduled_job.update_next_run_at

      # Notify (optional)
      PushNotificationService.notify_project(
        project_id: scheduled_job.project_id,
        title: "Scheduled job completed",
        body: scheduled_job.name,
        url: "/projects/#{scheduled_job.project_id}/scheduled_jobs/#{scheduled_job.id}"
      )

      # Log success
      Rails.logger.info "Scheduled job #{scheduled_job.name} completed successfully"

    rescue PiRpcService::Error => e
      handle_pi_error(scheduled_job, e)
    rescue => e
      handle_generic_error(scheduled_job, e)
    end
  end

  private

  def build_prompt_for_job(scheduled_job)
    instructions = BrowserAgentInstructions.text
    identity_context = PersonalKnowledgeRecallService.core_context

    context_parts = []

    project = scheduled_job.project

    if project.context_notes.any?
      context_parts << "## Project Context"
      context_parts += project.context_notes.map(&:to_context_string)
    end

    active_todos = project.todos.active.by_position
    if active_todos.any?
      context_parts << "## Active TODOs"
      context_parts += active_todos.map { |t| "- [#{t.status.upcase}] #{t.content}" }
    end

    base = scheduled_job.prompt_template.to_s

    recall = PersonalKnowledgeRecallService.recall_for(base)

    assembled = []
    assembled << identity_context if identity_context.present?
    assembled << instructions
    assembled << context_parts.join("\n\n") if context_parts.any?
    assembled << recall if recall.present?
    assembled << base

    assembled.compact.join("\n\n---\n\n")
  end

  def run_pi_stream(prompt, assistant_message, provider:, model:)
    pi = PiRpcService.new(provider: provider, model: model)
    pi.start

    full_text = +""
    metadata = {}

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
          assistant_message.update!(content: full_text)
        end

        partial = assistant_event["partial"]
        if partial.is_a?(Hash)
          extracted = extract_metadata(partial)
          metadata.merge!(extracted) if extracted.present?
        end
      when "message_end"
        msg = event["message"]
        next unless msg.is_a?(Hash) && msg["role"] == "assistant"

        if full_text.empty? && msg["content"].is_a?(Array)
          extracted_text = extract_text_from_content(msg["content"])
          full_text = extracted_text if extracted_text.present?
        end

        metadata.merge!(extract_metadata(msg))
      when "agent_end"
        if full_text.blank? && event["messages"].is_a?(Array)
          last_assistant = event["messages"].reverse.find { |m| m.is_a?(Hash) && m["role"] == "assistant" }
          if last_assistant&.dig("content").is_a?(Array)
            extracted_text = extract_text_from_content(last_assistant["content"])
            full_text = extracted_text if extracted_text.present?
            metadata.merge!(extract_metadata(last_assistant))
          end
        end

        assistant_message.update!(content: full_text, metadata: metadata)
      end
    end
  ensure
    pi.stop rescue nil
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

  def execute_prompt_template(scheduled_job)
    Rails.logger.info "Executing scheduled job: #{scheduled_job.name}"

    defaults = PiModelsService.default_provider_model
    provider = scheduled_job.pi_provider.presence || defaults[:provider]
    model = scheduled_job.pi_model.presence || defaults[:model]

    Rails.logger.info "Scheduled job model: #{provider}/#{model}"

    # Create a conversation with the prompt result
    conversation = scheduled_job.project.conversations.create!(
      title: "Scheduled: #{scheduled_job.name}",
      system_prompt: ""
    )

    prompt = build_prompt_for_job(scheduled_job)

    conversation.messages.create!(role: "user", content: prompt)
    assistant_message = conversation.messages.create!(role: "assistant", content: "")

    run_pi_stream(prompt, assistant_message, provider: provider, model: model)

    Rails.logger.info "Created conversation #{conversation.id} for scheduled job"
    true
  end

  def handle_pi_error(scheduled_job, error)
    Rails.logger.error "Pi RPC error in scheduled job #{scheduled_job.name}: #{error.message}"
    scheduled_job.update!(status: "failed")

    PushNotificationService.notify_project(
      project_id: scheduled_job.project_id,
      title: "Scheduled job failed",
      body: "#{scheduled_job.name}: #{error.message}",
      url: "/projects/#{scheduled_job.project_id}/scheduled_jobs/#{scheduled_job.id}"
    )

    raise
  end

  def handle_generic_error(scheduled_job, error)
    Rails.logger.error "Scheduled job #{scheduled_job.name} failed: #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.backtrace

    scheduled_job.update!(status: "failed")

    PushNotificationService.notify_project(
      project_id: scheduled_job.project_id,
      title: "Scheduled job failed",
      body: "#{scheduled_job.name}: #{error.message}",
      url: "/projects/#{scheduled_job.project_id}/scheduled_jobs/#{scheduled_job.id}"
    )

    raise
  end
end
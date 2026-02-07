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

  def execute_prompt_template(scheduled_job)
    Rails.logger.info "Executing scheduled job: #{scheduled_job.name}"
    Rails.logger.info "Prompt template: #{scheduled_job.prompt_template}"

    # Create a conversation with the prompt result
    conversation = scheduled_job.project.conversations.create!(
      title: "Scheduled: #{scheduled_job.name}",
      system_prompt: ""
    )

    # Add the prompt as a user message
    user_message = conversation.messages.create!(
      role: "user",
      content: scheduled_job.prompt_template
    )

    # Add a placeholder assistant message
    assistant_message = conversation.messages.create!(
      role: "assistant",
      content: "Scheduled job executed: #{scheduled_job.prompt_template}"
    )

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

    # Re-raise for retry logic
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

    # Re-raise to let the job framework handle retries
    raise
  end
end
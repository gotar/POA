# frozen_string_literal: true

class ScheduledJobTickJob < ApplicationJob
  queue_as :default

  # Periodic scheduler: enqueue due scheduled jobs.
  # This runs via Solid Queue recurring tasks.
  def perform(limit: 20)
    now = Time.current

    begin
      RuntimeMetric.set("scheduled_jobs.last_tick_at", now.iso8601)
    rescue ActiveRecord::StatementInvalid
      # migration not yet applied
    end

    due = ScheduledJob.active.due
      .where.not(status: ["running", "queued", "pending"]) # pending kept for backwards compatibility
      .order(next_run_at: :asc)
      .limit(limit)

    enqueued = 0

    due.each do |job|
      # Best-effort de-dupe: mark as pending only if not running.
      updated = ScheduledJob.where(id: job.id)
        .where.not(status: ["running", "queued", "pending"])
        .update_all(status: "queued", last_enqueued_at: now, updated_at: now)

      next unless updated == 1

      ScheduledJobRunnerJob.perform_later(job.id)
      enqueued += 1
    end

    if enqueued.positive?
      begin
        RuntimeMetric.set("scheduled_jobs.last_enqueue_at", now.iso8601)
        RuntimeMetric.increment("scheduled_jobs.enqueued_count", by: enqueued)
      rescue ActiveRecord::StatementInvalid
        # migration not yet applied
      end
    end
  end
end

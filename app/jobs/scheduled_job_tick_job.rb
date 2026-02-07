# frozen_string_literal: true

class ScheduledJobTickJob < ApplicationJob
  queue_as :default

  # Periodic scheduler: enqueue due scheduled jobs.
  # This runs via Solid Queue recurring tasks.
  def perform(limit: 20)
    due = ScheduledJob.active.due
      .where.not(status: "running")
      .order(next_run_at: :asc)
      .limit(limit)

    due.each do |job|
      # Best-effort de-dupe: mark as pending only if not running.
      updated = ScheduledJob.where(id: job.id).where.not(status: "running").update_all(status: "pending")
      next unless updated == 1

      ScheduledJobRunnerJob.perform_later(job.id)
    end
  end
end

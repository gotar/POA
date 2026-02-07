# frozen_string_literal: true

class MonitoringController < ApplicationController
  def index
    @projects = Project.all.includes(:scheduled_jobs, :conversations, :todos)
    @scheduled_jobs = ScheduledJob.includes(:project).order(created_at: :desc).limit(50)

    begin
      @scheduler_last_tick_at = RuntimeMetric.time("scheduled_jobs.last_tick_at")
      @scheduler_last_enqueue_at = RuntimeMetric.time("scheduled_jobs.last_enqueue_at")
      @scheduler_enqueued_count = RuntimeMetric.get("scheduled_jobs.enqueued_count").to_i
    rescue ActiveRecord::StatementInvalid
      @scheduler_last_tick_at = nil
      @scheduler_last_enqueue_at = nil
      @scheduler_enqueued_count = 0
    end

    # Job monitoring (with error handling for missing tables)
    begin
      @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(20)
      @jobs_by_status = SolidQueue::Job.group(:status).count
      @failed_jobs_count = SolidQueue::Job.where(status: "failed").count
    rescue ActiveRecord::StatementInvalid
      # SolidQueue tables don't exist
      @recent_jobs = []
      @jobs_by_status = {}
      @failed_jobs_count = 0
    end
  end

  def jobs
    begin
      @jobs = SolidQueue::Job.order(created_at: :desc).page(params[:page]).per(50)
    rescue ActiveRecord::StatementInvalid
      @jobs = []
    end
  end
end
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

    begin
      @heartbeat_last_run_at = RuntimeMetric.time("heartbeat.last_run_at")
      @heartbeat_last_status = RuntimeMetric.get("heartbeat.last_status")
      @heartbeat_last_duration_ms = RuntimeMetric.get("heartbeat.last_duration_ms").to_i
      @heartbeat_last_alerts = JSON.parse(RuntimeMetric.get("heartbeat.last_alerts").to_s) rescue []

      @agent_heartbeat_last_run_at = RuntimeMetric.time("heartbeat.agent_last_run_at")
      @agent_heartbeat_last_status = RuntimeMetric.get("heartbeat.agent_last_status")
      @agent_heartbeat_last_provider = RuntimeMetric.get("heartbeat.agent_last_provider").to_s
      @agent_heartbeat_last_model = RuntimeMetric.get("heartbeat.agent_last_model").to_s
      @agent_heartbeat_last_message = RuntimeMetric.get("heartbeat.agent_last_message").to_s
      @agent_heartbeat_last_error = RuntimeMetric.get("heartbeat.agent_last_error").to_s

      @polish_last_run_at = RuntimeMetric.time("personal_knowledge.polish_last_run_at")
      @polish_last_status = RuntimeMetric.get("personal_knowledge.polish_last_status")
    rescue ActiveRecord::StatementInvalid
      @heartbeat_last_run_at = nil
      @heartbeat_last_status = nil
      @heartbeat_last_duration_ms = 0
      @heartbeat_last_alerts = []

      @agent_heartbeat_last_run_at = nil
      @agent_heartbeat_last_status = nil
      @agent_heartbeat_last_provider = ""
      @agent_heartbeat_last_model = ""
      @agent_heartbeat_last_message = ""
      @agent_heartbeat_last_error = ""

      @polish_last_run_at = nil
      @polish_last_status = nil
    end

    # Heartbeat settings (ENV defaults, overridable from UI)
    @heartbeat_agent_enabled = bool_setting("heartbeat.agent_enabled", default: ENV.fetch("HEARTBEAT_AGENT_ENABLED", "true") == "true")
    @heartbeat_push_alerts_enabled = bool_setting("heartbeat.push_alerts_enabled", default: ENV.fetch("HEARTBEAT_PUSH_ALERTS", "false") == "true")
    @heartbeat_agent_skip_when_busy = bool_setting("heartbeat.agent_skip_when_busy", default: ENV.fetch("HEARTBEAT_AGENT_SKIP_WHEN_BUSY", "true") == "true")

    # Heartbeat history
    begin
      @heartbeat_events = HeartbeatEvent.order(started_at: :desc).limit(50)
    rescue ActiveRecord::StatementInvalid, NameError
      @heartbeat_events = []
    end

    # Job monitoring (with error handling for missing tables)
    load_job_metrics
  end

  def jobs
    load_jobs_list
  end

  def run_heartbeat
    SystemHeartbeatJob.perform_later

    respond_to do |format|
      format.html { redirect_to monitoring_path, notice: "Heartbeat queued" }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "toast-container",
          partial: "shared/toast",
          locals: { message: "Heartbeat queued", type: :success }
        )
      end
    end
  end

  def run_polish
    PersonalKnowledgePolishJob.perform_later

    respond_to do |format|
      format.html { redirect_to monitoring_path, notice: "Living docs polish queued" }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "toast-container",
          partial: "shared/toast",
          locals: { message: "Living docs polish queued", type: :success }
        )
      end
    end
  end

  def update_heartbeat_settings
    agent_enabled = params[:agent_enabled].to_s == "1"
    push_alerts_enabled = params[:push_alerts_enabled].to_s == "1"
    skip_when_busy = params[:agent_skip_when_busy].to_s == "1"

    RuntimeMetric.set("heartbeat.agent_enabled", agent_enabled ? "true" : "false")
    RuntimeMetric.set("heartbeat.push_alerts_enabled", push_alerts_enabled ? "true" : "false")
    RuntimeMetric.set("heartbeat.agent_skip_when_busy", skip_when_busy ? "true" : "false")

    respond_to do |format|
      format.html { redirect_to monitoring_path, notice: "Heartbeat settings updated" }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "toast-container",
          partial: "shared/toast",
          locals: { message: "Heartbeat settings updated", type: :success }
        )
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    respond_to do |format|
      format.html { redirect_to monitoring_path, alert: "Failed to update settings: #{e.message}" }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "toast-container",
          partial: "shared/toast",
          locals: { message: "Failed to update settings", type: :error }
        )
      end
    end
  end

  private

  def load_job_metrics
    @recent_jobs = solid_queue_jobs_scope.limit(20)
    @jobs_by_status = solid_queue_status_counts
    @failed_jobs_count = @jobs_by_status.fetch("failed", 0)
  rescue ActiveRecord::StatementInvalid, NameError
    @recent_jobs = []
    @jobs_by_status = {}
    @failed_jobs_count = 0
  end

  def load_jobs_list
    @jobs_error = nil
    @jobs = solid_queue_jobs_scope.limit(500)
  rescue ActiveRecord::StatementInvalid, NameError => e
    @jobs = []
    @jobs_error = e
  end

  def solid_queue_jobs_scope
    SolidQueue::Job
      .includes(:ready_execution, :claimed_execution, :failed_execution, :scheduled_execution, :blocked_execution)
      .order(created_at: :desc)
  end

  def solid_queue_status_counts
    pending = SolidQueue::ReadyExecution.count +
              SolidQueue::ScheduledExecution.count +
              SolidQueue::BlockedExecution.count

    {
      "pending" => pending,
      "running" => SolidQueue::ClaimedExecution.count,
      "completed" => SolidQueue::Job.where.not(finished_at: nil).count,
      "failed" => SolidQueue::FailedExecution.count
    }
  end

  def bool_setting(key, default:)
    v = RuntimeMetric.get(key)
    return default if v.blank?

    v.to_s == "true"
  rescue ActiveRecord::StatementInvalid
    default
  end
end

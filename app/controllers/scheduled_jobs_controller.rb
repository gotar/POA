# frozen_string_literal: true

class ScheduledJobsController < ApplicationController
  before_action :set_project
  before_action :set_scheduled_job, only: %i[show edit update destroy run_now toggle runs status]

  # GET /projects/:project_id/scheduled_jobs
  def index
    @scheduled_jobs = @project.scheduled_jobs.order(created_at: :desc)
    @scheduled_job = @project.scheduled_jobs.build

    begin
      @scheduler_last_tick_at = RuntimeMetric.time("scheduled_jobs.last_tick_at")
      @scheduler_last_enqueue_at = RuntimeMetric.time("scheduled_jobs.last_enqueue_at")
      @scheduler_enqueued_count = RuntimeMetric.get("scheduled_jobs.enqueued_count").to_i
    rescue ActiveRecord::StatementInvalid
      @scheduler_last_tick_at = nil
      @scheduler_last_enqueue_at = nil
      @scheduler_enqueued_count = 0
    end
  end

  # GET /projects/:project_id/scheduled_jobs/:id
  def show
    @run_conversations = @scheduled_job.conversations
      .where(project_id: @project.id)
      .order(created_at: :desc)
      .limit(30)
      .includes(:messages)
  end

  # GET /projects/:project_id/scheduled_jobs/new
  def new
    @scheduled_job = @project.scheduled_jobs.build

    defaults = PiModelsService.default_provider_model
    @scheduled_job.pi_provider ||= defaults[:provider]
    @scheduled_job.pi_model ||= defaults[:model]

    @scheduled_job.prompt_template ||= ScheduledJob.default_prompt_template
  end

  # GET /projects/:project_id/scheduled_jobs/:id/edit
  def edit
  end

  # POST /projects/:project_id/scheduled_jobs
  def create
    @scheduled_job = @project.scheduled_jobs.build(scheduled_job_params)

    if @scheduled_job.save
      respond_to do |format|
        format.html { redirect_to [@project, @scheduled_job], notice: "Scheduled job created" }
        format.turbo_stream { redirect_to [@project, @scheduled_job] }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/:project_id/scheduled_jobs/:id
  def update
    if @scheduled_job.update(scheduled_job_params)
      respond_to do |format|
        format.html { redirect_to [@project, @scheduled_job], notice: "Scheduled job updated" }
        format.turbo_stream { redirect_to [@project, @scheduled_job] }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:project_id/scheduled_jobs/:id
  def destroy
    @scheduled_job.destroy!

    respond_to do |format|
      format.html { redirect_to project_scheduled_jobs_path(@project), notice: "Scheduled job deleted" }
      format.turbo_stream
    end
  end

  # POST /projects/:project_id/scheduled_jobs/:id/run_now
  def run_now
    # Reflect intent immediately in the UI.
    @scheduled_job.update!(status: "queued", last_enqueued_at: Time.current)

    ScheduledJobRunnerJob.perform_later(@scheduled_job.id)

    respond_to do |format|
      format.html { redirect_to [@project, @scheduled_job], notice: "Job queued for execution" }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("scheduled_job_status", partial: "scheduled_jobs/status_frame", locals: { project: @project, scheduled_job: @scheduled_job, poll: true }),
          turbo_stream.replace("scheduled_job_runs", partial: "scheduled_jobs/runs_frame", locals: { project: @project, scheduled_job: @scheduled_job, poll: true })
        ]
      end
    end
  end

  # GET /projects/:project_id/scheduled_jobs/:id/runs
  def runs
    @run_conversations = @scheduled_job.conversations
      .where(project_id: @project.id)
      .order(created_at: :desc)
      .limit(30)
      .includes(:messages)

    render layout: false
  end

  # GET /projects/:project_id/scheduled_jobs/:id/status
  def status
    render layout: false
  end

  # POST /projects/:project_id/scheduled_jobs/:id/toggle
  def toggle
    @scheduled_job.update!(active: !@scheduled_job.active?)

    respond_to do |format|
      format.html { redirect_to [@project, @scheduled_job] }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_scheduled_job
    @scheduled_job = @project.scheduled_jobs.find(params[:id])
  end

  def scheduled_job_params
    permitted = params.expect(scheduled_job: %i[name cron_expression prompt_template active selected_model pi_provider pi_model])

    # Prefer combined selected_model from the UI combobox
    if permitted[:selected_model].present?
      provider, model = permitted[:selected_model].to_s.split(":", 2)
      permitted[:pi_provider] = provider
      permitted[:pi_model] = model
    end

    permitted.except(:selected_model)
  end
end
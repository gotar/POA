# frozen_string_literal: true

class ScheduledJobsController < ApplicationController
  before_action :set_project
  before_action :set_scheduled_job, only: %i[show edit update destroy run_now toggle]

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
  end

  # GET /projects/:project_id/scheduled_jobs/new
  def new
    @scheduled_job = @project.scheduled_jobs.build

    defaults = PiModelsService.default_provider_model
    @scheduled_job.pi_provider ||= defaults[:provider]
    @scheduled_job.pi_model ||= defaults[:model]
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
    ScheduledJobRunnerJob.perform_later(@scheduled_job.id)

    respond_to do |format|
      format.html { redirect_to [@project, @scheduled_job], notice: "Job queued for execution" }
      format.turbo_stream { redirect_to [@project, @scheduled_job] }
    end
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
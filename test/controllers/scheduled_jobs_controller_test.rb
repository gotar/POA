# frozen_string_literal: true

require "test_helper"

class ScheduledJobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = create_project
  end

  # Index
  test "should get index" do
    get project_scheduled_jobs_url(@project)
    assert_response :success
  end

  test "index should show scheduled jobs for project" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    get project_scheduled_jobs_url(@project)

    assert_response :success
    assert_includes assigns(:scheduled_jobs), job
  end

  # Show
  test "should show scheduled job" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    get project_scheduled_job_url(@project, job)

    assert_response :success
    assert_equal job, assigns(:scheduled_job)
  end

  test "should not show scheduled job from different project" do
    other_project = create_project(name: "Other")
    job = other_project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    get project_scheduled_job_url(@project, job)

    assert_response :not_found
  end

  # New
  test "should get new" do
    get new_project_scheduled_job_url(@project)

    assert_response :success
    assert_instance_of ScheduledJob, assigns(:scheduled_job)
    assert_equal @project, assigns(:scheduled_job).project
  end

  # Create
  test "should create scheduled job" do
    assert_difference("ScheduledJob.count") do
      post project_scheduled_jobs_url(@project), params: {
        scheduled_job: {
          name: "New Job",
          cron_expression: "0 9 * * *",
          prompt_template: "Test prompt",
          active: true
        }
      }
    end

    job = ScheduledJob.last
    assert_equal "New Job", job.name
    assert_equal "0 9 * * *", job.cron_expression
    assert_equal "Test prompt", job.prompt_template
    assert job.active?
    assert_redirected_to [@project, job]
  end

  test "should not create invalid scheduled job" do
    assert_no_difference("ScheduledJob.count") do
      post project_scheduled_jobs_url(@project), params: {
        scheduled_job: { name: "", cron_expression: "0 9 * * *", prompt_template: "Test" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit
  test "should get edit" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    get edit_project_scheduled_job_url(@project, job)

    assert_response :success
    assert_equal job, assigns(:scheduled_job)
  end

  # Update
  test "should update scheduled job" do
    job = @project.scheduled_jobs.create!(
      name: "Old Name",
      cron_expression: "0 9 * * *",
      prompt_template: "Old prompt"
    )

    patch project_scheduled_job_url(@project, job), params: {
      scheduled_job: {
        name: "New Name",
        cron_expression: "0 10 * * *",
        prompt_template: "New prompt"
      }
    }

    job.reload
    assert_equal "New Name", job.name
    assert_equal "0 10 * * *", job.cron_expression
    assert_equal "New prompt", job.prompt_template
    assert_redirected_to [@project, job]
  end

  test "should not update with invalid data" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    patch project_scheduled_job_url(@project, job), params: {
      scheduled_job: { name: "", cron_expression: "0 9 * * *", prompt_template: "Test" }
    }

    job.reload
    assert_equal "Test Job", job.name
    assert_response :unprocessable_entity
  end

  # Destroy
  test "should destroy scheduled job" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    assert_difference("ScheduledJob.count", -1) do
      delete project_scheduled_job_url(@project, job)
    end

    assert_redirected_to project_scheduled_jobs_url(@project)
  end

  # Run now
  test "should queue job for immediate execution" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    assert_enqueued_with(job: ScheduledJobRunnerJob, args: [job.id]) do
      post run_now_project_scheduled_job_url(@project, job)
    end

    assert_redirected_to [@project, job]
  end

  # Toggle
  test "should activate inactive job" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt",
      active: false
    )

    post toggle_project_scheduled_job_url(@project, job)

    job.reload
    assert job.active?
  end

  test "should deactivate active job" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt",
      active: true
    )

    post toggle_project_scheduled_job_url(@project, job)

    job.reload
    assert_not job.active?
  end

  # Project isolation
  test "should not access scheduled job from different project" do
    other_project = create_project(name: "Other")
    job = other_project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt"
    )

    get project_scheduled_job_url(@project, job)
    assert_response :not_found

    patch project_scheduled_job_url(@project, job), params: { scheduled_job: { name: "Updated" } }
    assert_response :not_found

    delete project_scheduled_job_url(@project, job)
    assert_response :not_found
  end
end
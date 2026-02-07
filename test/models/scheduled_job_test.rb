# frozen_string_literal: true

require "test_helper"

class ScheduledJobTest < ActiveSupport::TestCase
  setup do
    @project = create_project
  end

  # Validations
  test "should be valid with required attributes" do
    job = @project.scheduled_jobs.build(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test prompt",
      active: true
    )
    assert job.valid?
  end

  test "should require name" do
    job = @project.scheduled_jobs.build(cron_expression: "0 9 * * *", prompt_template: "Test")
    assert_not job.valid?
    assert_includes job.errors[:name], "can't be blank"
  end

  test "should require cron_expression" do
    job = @project.scheduled_jobs.build(name: "Test", prompt_template: "Test")
    assert_not job.valid?
    assert_includes job.errors[:cron_expression], "can't be blank"
  end

  test "should require prompt_template" do
    job = @project.scheduled_jobs.build(name: "Test", cron_expression: "0 9 * * *")
    assert_not job.valid?
    assert_includes job.errors[:prompt_template], "can't be blank"
  end

  test "should allow valid status values" do
    valid_statuses = %w[pending running completed failed paused]
    valid_statuses.each do |status|
      job = @project.scheduled_jobs.build(
        name: "Test",
        cron_expression: "0 9 * * *",
        prompt_template: "Test",
        status: status
      )
      assert job.valid?, "Status #{status} should be valid"
    end
  end

  test "should not allow invalid status values" do
    job = @project.scheduled_jobs.build(
      name: "Test",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      status: "invalid"
    )
    assert_not job.valid?
    assert_includes job.errors[:status], "is not included in the list"
  end

  # Scopes
  test "active scope returns only active jobs" do
    active_job = @project.scheduled_jobs.create!(
      name: "Active Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: true
    )
    inactive_job = @project.scheduled_jobs.create!(
      name: "Inactive Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: false
    )

    active_results = ScheduledJob.active
    assert_includes active_results, active_job
    assert_not_includes active_results, inactive_job
  end

  test "due scope returns jobs with next_run_at in the past" do
    due_job = @project.scheduled_jobs.create!(
      name: "Due Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test"
    )
    # Manually set next_run_at to past after creation to avoid callback override
    due_job.update_columns(next_run_at: 1.hour.ago)

    future_job = @project.scheduled_jobs.create!(
      name: "Future Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test"
    )

    due_results = ScheduledJob.due
    assert_includes due_results, due_job
    assert_not_includes due_results, future_job
  end

  test "for_project scope filters by project" do
    other_project = create_project(name: "Other")
    job1 = @project.scheduled_jobs.create!(
      name: "Job 1",
      cron_expression: "0 9 * * *",
      prompt_template: "Test"
    )
    job2 = other_project.scheduled_jobs.create!(
      name: "Job 2",
      cron_expression: "0 9 * * *",
      prompt_template: "Test"
    )

    project_results = ScheduledJob.for_project(@project)
    assert_includes project_results, job1
    assert_not_includes project_results, job2
  end

  # Instance methods
  test "due? returns true when job should run" do
    job = @project.scheduled_jobs.create!(
      name: "Due Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: true
    )
    # Manually set next_run_at to past after creation
    job.update_columns(next_run_at: 1.hour.ago)

    assert job.due?
  end

  test "due? returns false when job is inactive" do
    job = @project.scheduled_jobs.create!(
      name: "Inactive Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: false
    )
    # Even with past next_run_at, inactive jobs shouldn't be due
    job.update_columns(next_run_at: 1.hour.ago)

    assert_not job.due?
  end

  test "due? returns false when next_run_at is in future" do
    job = @project.scheduled_jobs.create!(
      name: "Future Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: true
    )
    # next_run_at should be in future by default from callback

    assert_not job.due?
  end

  # Cron parsing (basic implementation)
  test "calculate_next_run_at handles simple daily cron" do
    job = @project.scheduled_jobs.build(
      name: "Daily Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test"
    )

    # From 8 AM, should schedule for 9 AM same day
    from_time = Time.new(2023, 1, 1, 8, 0, 0)
    next_run = job.calculate_next_run_at(from_time)

    expected = Time.new(2023, 1, 1, 9, 0, 0)
    assert_equal expected, next_run
  end

  test "calculate_next_run_at handles interval cron" do
    job = @project.scheduled_jobs.build(
      name: "30 Min Job",
      cron_expression: "*/30 * * * *",
      prompt_template: "Test"
    )

    # From 8:15, should schedule for 8:30
    from_time = Time.new(2023, 1, 1, 8, 15, 0)
    next_run = job.calculate_next_run_at(from_time)

    expected = Time.new(2023, 1, 1, 8, 30, 0)
    assert_equal expected, next_run
  end

  # Callbacks
  test "update_next_run_at is called before save" do
    job = @project.scheduled_jobs.build(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: true
    )

    job.save!
    assert_not_nil job.next_run_at
  end

  # Mark as run
  test "mark_as_run! updates timestamps and recalculates next run" do
    job = @project.scheduled_jobs.create!(
      name: "Test Job",
      cron_expression: "0 9 * * *",
      prompt_template: "Test",
      active: true
    )

    original_next_run = job.next_run_at

    travel_to 1.hour.from_now do
      job.mark_as_run!
    end

    job.reload
    assert_not_nil job.last_run_at
    assert_not_equal original_next_run, job.next_run_at
  end
end
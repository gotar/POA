# frozen_string_literal: true

class ScheduledJob < ApplicationRecord
  belongs_to :project

  validates :name, presence: true, length: { maximum: 255 }
  validates :cron_expression, presence: true
  validates :prompt_template, presence: true
  validates :status, inclusion: { in: %w[pending running completed failed paused] }, allow_nil: true

  before_save :update_next_run_at

  # Scopes
  scope :active, -> { where(active: true) }
  scope :due, -> { where("next_run_at <= ?", Time.current) }
  scope :for_project, ->(project) { where(project: project) }

  # Check if job should run
  def due?
    active? && next_run_at.present? && next_run_at <= Time.current
  end

  # Calculate next run time from cron expression
  def calculate_next_run_at(from_time = Time.current)
    return nil unless cron_expression.present?

    # Simple cron parsing (for demo - in production use a proper cron gem)
    begin
      # This is a simplified implementation
      # In production, use something like 'rufus-scheduler' or 'fugit'
      parse_cron_expression(from_time)
    rescue
      nil
    end
  end

  # Update the next run time
  def update_next_run_at
    self.next_run_at = calculate_next_run_at(last_run_at || Time.current)
  end

  # Mark as run
  def mark_as_run!
    update!(last_run_at: Time.current, next_run_at: calculate_next_run_at)
  end

  # Simple cron parser (very basic implementation)
  private

  def parse_cron_expression(from_time)
    # This is a very simplified cron parser
    # Format: "MIN HOUR DAY MONTH DAYOFWEEK"
    # Examples: "0 9 * * *" (daily at 9am), "*/30 * * * *" (every 30 minutes)

    parts = cron_expression.split
    return nil unless parts.length == 5

    min, hour, day, month, dow = parts

    time = from_time.dup

    # Handle minutes
    if min == "*"
      # Every minute - just add 1 minute
      time += 1.minute
    elsif min.start_with?("*/")
      # Every N minutes
      interval = min[2..].to_i
      minutes_to_add = interval - (time.min % interval)
      time += minutes_to_add.minutes
    else
      # Specific minute
      target_min = min.to_i
      if time.min < target_min
        time = time.change(min: target_min)
      else
        time = time.change(min: target_min) + 1.hour
      end
    end

    # For simplicity, we'll just support basic patterns
    # In production, use a proper cron library
    time
  end
end
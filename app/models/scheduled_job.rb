# frozen_string_literal: true

class ScheduledJob < ApplicationRecord
  belongs_to :project
  has_many :conversations, dependent: :nullify

  validates :name, presence: true, length: { maximum: 255 }
  validates :cron_expression, presence: true
  validates :prompt_template, presence: true
  validates :status, inclusion: { in: %w[pending queued running completed failed paused] }, allow_nil: true

  validates :pi_provider, length: { maximum: 100 }, allow_blank: true
  validates :pi_model, length: { maximum: 200 }, allow_blank: true

  before_save :update_next_run_at

  # Ensure Fugit is loaded in production boot.
  require "fugit"

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

    offset = from_time.to_time.utc_offset
    tz = format_utc_offset(offset)

    expr = cron_expression.to_s.strip
    expr = "#{expr} #{tz}" if expr.split.size < 6

    cron = Fugit::Cron.parse(expr)
    return nil unless cron

    nt = cron.next_time(from_time)
    return nil unless nt

    # EtOrbi::EoTime -> preserve the caller's UTC offset
    Time.at(nt.to_f).getlocal(offset)
  rescue StandardError
    nil
  end

  # Update the next run time
  def update_next_run_at
    self.next_run_at = calculate_next_run_at(last_run_at || Time.current)
  end

  def format_utc_offset(offset_seconds)
    sign = offset_seconds.negative? ? "-" : "+"
    abs = offset_seconds.abs
    hours = abs / 3600
    mins = (abs % 3600) / 60
    format("%s%02d:%02d", sign, hours, mins)
  end

  # Mark as run
  def mark_as_run!
    now = Time.current

    # Treat this as "we executed the job", so advance the schedule by at least one occurrence.
    base = next_run_at.presence || now

    next_time = calculate_next_run_at(base + 1.second)

    # Use update_columns to avoid before_save callback overriding next_run_at.
    update_columns(last_run_at: now, next_run_at: next_time, updated_at: now)
  end

  def self.default_prompt_template
    <<~PROMPT.strip
      Create a concise scheduled report for Oskar Szrajer ("gotar").

      Context:
      - Timezone: Europe/Warsaw (Poland)
      - Work: Ruby/web developer; consulting (Gotar, Ruby/Elixir) + Senior Software Developer at Impactpool (Rails/Hotwire/ViewComponents, integrations like BigQuery/APIs)
      - Other: Aikido instructor (Sesshinkan Dojo, Gdynia)

      Output (Markdown, no fluff):
      1) Summary (max 5 bullets)
      2) Active TODOs: list each with a suggested next action
      3) Risks/blockers (if any)
      4) Next priorities (top 3)
    PROMPT
  end

end
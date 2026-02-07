# frozen_string_literal: true

class Todo < ApplicationRecord
  belongs_to :project

  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending in_progress completed cancelled] }
  validates :priority, inclusion: { in: 1..5, allow_nil: true }

  # Status scopes
  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :active, -> { where(status: %w[pending in_progress]) }

  # Priority ordering
  scope :by_priority, -> { order(priority: :desc, created_at: :asc) }
  scope :by_position, -> { order(position: :asc, created_at: :asc) }

  # Status helpers
  def pending?
    status == "pending"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  # State transitions
  def start!
    update!(status: "in_progress")
  end

  def complete!
    update!(status: "completed")
  end

  def cancel!
    update!(status: "cancelled")
  end

  def reopen!
    update!(status: "pending")
  end

  # For API/JSON output
  def to_h
    {
      id: id,
      content: content,
      status: status,
      priority: priority,
      created_at: created_at.iso8601
    }
  end
end

# frozen_string_literal: true

class MessageToolCall < ApplicationRecord
  belongs_to :message

  validates :tool_call_id, presence: true
  validates :tool_name, presence: true
  validates :status, inclusion: { in: %w[running done error] }

  scope :recent_first, -> { order(started_at: :desc, created_at: :desc) }
  scope :oldest_first, -> { order(started_at: :asc, created_at: :asc) }
end

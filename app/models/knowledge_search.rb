# frozen_string_literal: true

class KnowledgeSearch < ApplicationRecord
  MODES = %w[search vsearch query].freeze
  STATUSES = %w[queued running completed failed].freeze

  validates :query, presence: true
  validates :mode, presence: true, inclusion: { in: MODES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def done?
    status == "completed" || status == "failed"
  end
end

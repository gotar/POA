# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :project

  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :category, inclusion: { in: %w[context knowledge reference], allow_blank: true }

  # Category scopes
  scope :context, -> { where(category: "context") }
  scope :knowledge, -> { where(category: "knowledge") }
  scope :reference, -> { where(category: "reference") }

  scope :recent, -> { order(updated_at: :desc) }

  # Categories for dropdown
  CATEGORIES = {
    "context" => "AI Context (included in prompts)",
    "knowledge" => "Knowledge Base (searchable)",
    "reference" => "Reference Material"
  }.freeze

  # For AI context injection
  def to_context_string
    <<~MARKDOWN
      ## #{title}
      #{content}
    MARKDOWN
  end
end

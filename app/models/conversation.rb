# frozen_string_literal: true

class Conversation < ApplicationRecord
  belongs_to :project
  belongs_to :scheduled_job, optional: true

  has_many :messages, dependent: :destroy

  scope :unarchived, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  validates :title, presence: true, length: { maximum: 255 }

  # Optional PI model overrides for this conversation
  validates :pi_provider, length: { maximum: 100 }, allow_nil: true
  validates :pi_model, length: { maximum: 200 }, allow_nil: true

  # Generate a title from the first user message
  def generate_title_from_first_message!
    return if title.present?

    first_user_message = messages.where(role: "user").first
    return unless first_user_message

    # Use first 50 chars of message as title
    self.title = first_user_message.content.to_s.truncate(50)
    save!
  end

  # Scopes
  scope :recent, -> { order(updated_at: :desc) }
  scope :for_project, ->(project) { where(project: project) }

  # Get recent conversations for a project
  def self.recent_for_project(project, limit = 20)
    for_project(project).recent.limit(limit)
  end
end

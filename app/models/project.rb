# frozen_string_literal: true

class Project < ApplicationRecord
  include Colorable

  has_many :conversations, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :knowledge_bases, class_name: "KnowledgeBase", dependent: :destroy
  has_many :scheduled_jobs, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :icon, length: { maximum: 10 }

  # Available colors for projects (moved to concern)
  COLORS = Colorable::COLORS

  # Default icon options (emoji)
  ICONS = %w[🚀 💼 🎯 📚 🛠️ 🎨 📊 🏠 🌟 💡].freeze

  # Scopes
  scope :recent, -> { order(updated_at: :desc) }
  scope :by_name, -> { order(:name) }
  scope :empty, -> { 
    left_joins(:conversations, :todos, :notes, :knowledge_bases, :scheduled_jobs)
    .where(conversations: { id: nil }, todos: { id: nil }, notes: { id: nil }, knowledge_bases: { id: nil }, scheduled_jobs: { id: nil })
  }
  scope :old, -> { where('updated_at < ?', 30.days.ago) }
  scope :archived, -> { where(archived: true) }
  scope :active, -> { where(archived: [false, nil]) }

  # Get active todos (pending + in_progress)
  def active_todos
    todos.where.not(status: %w[completed cancelled]).order(:position, :priority)
  end

  # Get context notes (for AI context)
  def context_notes
    notes.where(category: "context").order(updated_at: :desc)
  end

  # Get recent conversations
  def recent_conversations(limit = 10)
    conversations.order(updated_at: :desc).limit(limit)
  end

  # Check if project is empty (no content)
  def empty?
    conversations.empty? && todos.empty? && notes.empty? && knowledge_bases.empty? && scheduled_jobs.empty?
  end

  # Check if project is old (not updated in 30 days)
  def old?
    updated_at < 30.days.ago
  end

  # Archive/unarchive project
  def archive!
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end

  # Summary for display
  def summary
    {
      conversations_count: conversations.count,
      todos_pending: todos.where(status: "pending").count,
      todos_completed: todos.where(status: "completed").count,
      notes_count: notes.count,
      knowledge_bases_count: knowledge_bases.count
    }
  end

  # Generate a random color if not set
  def ensure_color!
    update!(color: COLORS.sample) unless color.present?
  end
end

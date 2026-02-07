# frozen_string_literal: true

class KnowledgeBase < ApplicationRecord
  belongs_to :project

  has_many :attachments, as: :attachable, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :category, presence: true, inclusion: { in: %w[context reference code example] }

  # Tags are stored as JSON array
  # Note: SQLite doesn't support JSON columns natively, so we'll store as text and parse manually

  # Custom getter for tags
  def tags
    return [] if super.blank?
    JSON.parse(super) rescue []
  end

  # Custom setter for tags
  def tags=(value)
    super(value.is_a?(Array) ? value.to_json : value)
  end

  before_save :normalize_tags

  after_save :sync_with_qmd
  after_destroy :sync_with_qmd

  # Search knowledge bases by content and title
  def self.search(query, project = nil)
    # Use LOWER for case-insensitive search in SQLite
    scope = where("LOWER(title) LIKE LOWER(?) OR LOWER(content) LIKE LOWER(?)", "%#{query}%", "%#{query}%")
    scope = scope.where(project: project) if project
    scope
  end

  # Enhanced search using QMD semantic search
  def self.semantic_search(query, project = nil, limit: 10)
    qmd_service = QmdService.new

    # First, ensure knowledge base is indexed
    qmd_service.index_all

    results = qmd_service.search(query, limit: limit)

    # Filter by project if specified and map to database records
    if project
      project_kb_ids = project.knowledge_bases.pluck(:id)
      filtered_results = results.select { |r| project_kb_ids.include?(r['id']) }
      # Convert to ActiveRecord objects
      ids = filtered_results.map { |r| r['id'] }
      KnowledgeBase.where(id: ids).order(Arel.sql("FIELD(id, #{ids.join(',')})"))
    else
      # Return all results as ActiveRecord objects
      ids = results.map { |r| r['id'] }
      KnowledgeBase.where(id: ids).order(Arel.sql("FIELD(id, #{ids.join(',')})"))
    end
  rescue QmdService::Error => e
    Rails.logger.warn "QMD search failed, falling back to basic search: #{e.message}"
    search(query, project).limit(limit)
  end

  # Get knowledge bases by category
  def self.by_category(category, project = nil)
    scope = where(category: category)
    scope = scope.where(project: project) if project
    scope.order(:title)
  end

  # Get recent knowledge bases
  def self.recent(project = nil, limit = 10)
    scope = order(created_at: :desc)
    scope = scope.where(project: project) if project
    scope.limit(limit)
  end

  # Extract keywords from content for search
  def keywords
    content.scan(/\b\w{3,}\b/).uniq
  end

  # Normalize tags to lowercase
  def normalize_tags
    current_tags = tags
    if current_tags.is_a?(Array) && current_tags.any?
      self.tags = current_tags.map(&:to_s).map(&:downcase).uniq
    end
  end

  # Check if content contains code blocks
  def has_code?
    content.include?("```")
  end

  # Get code blocks from content
  def code_blocks
    content.scan(/```(\w+)?\n?(.*?)\n?```/m)
  end

  private

  def sync_with_qmd
    QmdService.new.sync_knowledge_base(self)
  rescue QmdService::Error => e
    Rails.logger.warn "Failed to sync knowledge base with QMD: #{e.message}"
    # Don't fail the save operation if QMD sync fails
  end
end
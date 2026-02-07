# frozen_string_literal: true

class QmdService
  class Error < StandardError; end

  def initialize
    @knowledge_base_path = Rails.root.join('storage', 'knowledge_base')
    FileUtils.mkdir_p(@knowledge_base_path) unless Dir.exist?(@knowledge_base_path)
  end

  # Index all knowledge base content from the database
  def index_all
    markdown_files = []

    # Export all knowledge base items to markdown files
    KnowledgeBase.find_each do |kb|
      filename = "#{kb.id}-#{kb.title.parameterize}.md"
      filepath = @knowledge_base_path.join(filename)

      File.write(filepath, knowledge_base_to_markdown(kb))
      markdown_files << filepath.to_s
    end

    # For now, just log that indexing would happen
    Rails.logger.info "QMD indexing would process #{markdown_files.length} files"

    { count: markdown_files.length, files: markdown_files }
  end

  # Search knowledge base using simple text matching (fallback)
  def search(query, limit: 10, threshold: 0.1)
    # Simple implementation - search through database
    results = KnowledgeBase.where(
      "LOWER(title) LIKE LOWER(?) OR LOWER(content) LIKE LOWER(?)",
      "%#{query}%", "%#{query}%"
    ).limit(limit)

    # Format results to match expected structure
    results.map do |kb|
      {
        'id' => kb.id,
        'title' => kb.title,
        'content' => kb.content.truncate(200),
        'score' => calculate_simple_score(kb, query),
        'category' => kb.category
      }
    end
  end

  # Add new content to knowledge base
  def add_content(title, content, project:, category: 'reference', tags: [])
    kb = KnowledgeBase.create!(
      project: project,
      title: title,
      content: content,
      category: category,
      tags: tags
    )

    # Export to markdown file
    filename = "#{kb.id}-#{kb.title.parameterize}.md"
    filepath = @knowledge_base_path.join(filename)
    File.write(filepath, knowledge_base_to_markdown(kb))

    kb
  end

  # Sync database changes to markdown files
  def sync_knowledge_base(knowledge_base)
    filename = "#{knowledge_base.id}-#{knowledge_base.title.parameterize}.md"
    filepath = @knowledge_base_path.join(filename)

    if knowledge_base.destroyed?
      File.delete(filepath) if File.exist?(filepath)
    else
      File.write(filepath, knowledge_base_to_markdown(knowledge_base))
    end
  end

  private

  def knowledge_base_to_markdown(kb)
    markdown = String.new

    # Front matter
    markdown << "---\n"
    markdown << "title: #{kb.title}\n"
    markdown << "category: #{kb.category}\n"
    markdown << "tags: #{kb.tags.join(', ')}\n" if kb.tags.present?
    markdown << "created: #{kb.created_at.iso8601}\n"
    markdown << "updated: #{kb.updated_at.iso8601}\n"
    markdown << "---\n\n"

    # Content
    markdown << "# #{kb.title}\n\n"
    markdown << "#{kb.content}\n\n"

    # Metadata
    markdown << "---\n"
    markdown << "*Category:* #{kb.category.titleize}\n"
    markdown << "*Tags:* #{kb.tags.join(', ')}\n" if kb.tags.present?
    markdown << "*Created:* #{kb.created_at.strftime('%B %d, %Y')}\n"
    markdown << "*Updated:* #{kb.updated_at.strftime('%B %d, %Y')}\n"

    markdown
  end

  def calculate_simple_score(kb, query)
    # Simple scoring based on title and content matches
    title_score = kb.title.downcase.include?(query.downcase) ? 0.8 : 0
    content_score = kb.content.downcase.include?(query.downcase) ? 0.6 : 0

    [title_score, content_score].max
  end
end
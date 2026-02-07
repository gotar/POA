# frozen_string_literal: true

class PersonalKnowledgeRecallService
  MAX_SNIPPET_CHARS = (ENV["PI_KNOWLEDGE_RECALL_SNIPPET_CHARS"].presence || "700").to_i
  MAX_RESULTS = (ENV["PI_KNOWLEDGE_RECALL_RESULTS"].presence || "4").to_i

  CORE_FILES = %w[SOUL.md IDENTITY.md USER.md].freeze

  def self.core_context
    PersonalKnowledgeService.ensure_setup!

    parts = []
    CORE_FILES.each do |name|
      abs = File.join(PersonalKnowledgeService.base_dir, name)
      next unless File.exist?(abs)

      text = File.read(abs).to_s.strip
      next if text.blank?

      parts << "## #{name}\n\n#{truncate(text, 2000)}"
    end

    return "" if parts.empty?

    "# Personal Identity & Preferences\n\n#{parts.join("\n\n---\n\n")}"
  rescue StandardError
    ""
  end

  def self.recall_for(query)
    q = query.to_s.strip
    return "" if q.blank?

    results = QmdCliService.search(q, mode: :query, limit: MAX_RESULTS + 3)

    filtered = results.filter_map do |r|
      file = r["file"].to_s
      rel = file.sub(%r{\Aqmd://[^/]+/}i, "")

      next if rel.blank?
      next if rel.casecmp("readme.md").zero?
      next if CORE_FILES.include?(rel)

      # Prefer durable notes
      next unless rel == "MEMORY.md" || rel.start_with?("topics/")

      {
        rel: rel,
        title: r["title"].presence || rel,
        score: r["score"],
        snippet: truncate(r["snippet"].to_s, MAX_SNIPPET_CHARS)
      }
    end

    filtered = filtered.first(MAX_RESULTS)
    return "" if filtered.empty?

    lines = []
    lines << "## Personal Knowledge Recall (QMD)"
    lines << "Use this as context. If it conflicts with the user, ask/verify and update the knowledge base." 

    filtered.each do |r|
      lines << "- Source: #{r[:rel]} (score #{r[:score]})"
      lines << "  Title: #{r[:title]}" if r[:title].present?
      if r[:snippet].present?
        snippet = r[:snippet].lines.map { |l| "  #{l.rstrip}" }.join("\n")
        lines << "  Snippet:\n#{snippet}"
      end
    end

    lines.join("\n")
  rescue StandardError
    ""
  end

  def self.truncate(s, max)
    t = s.to_s
    return t if t.length <= max

    t[0, max].rstrip + "…"
  end
end

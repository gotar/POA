# frozen_string_literal: true

class PersonalKnowledgeRecallService
  # NOTE: Following OpenClaw's philosophy, chat sessions should only load a small
  # set of "living docs" (plain Markdown files) as the source of truth.
  #
  # We do NOT run QMD retrieval during chat turns. QMD can be used in background
  # jobs to rebuild/refresh these living docs.

  CORE_FILES = %w[SOUL.md IDENTITY.md USER.md TOOLS.md].freeze
  MEMORY_FILE = "MEMORY.md"

  CORE_TRUNCATE_CHARS = (ENV["PI_KNOWLEDGE_CORE_CONTEXT_CHARS"].presence || "2200").to_i
  MEMORY_TRUNCATE_CHARS = (ENV["PI_KNOWLEDGE_MEMORY_CONTEXT_CHARS"].presence || "3000").to_i

  def self.core_context
    PersonalKnowledgeService.ensure_setup!

    parts = []
    CORE_FILES.each do |name|
      abs = File.join(PersonalKnowledgeService.base_dir, name)
      next unless File.exist?(abs)

      text = File.read(abs).to_s.strip
      next if text.blank?

      parts << "## #{name}\n\n#{truncate(text, CORE_TRUNCATE_CHARS)}"
    end

    return "" if parts.empty?

    "# Personal Identity & Preferences\n\n#{parts.join("\n\n---\n\n")}" 
  rescue StandardError
    ""
  end

  def self.memory_context
    PersonalKnowledgeService.ensure_setup!

    abs = File.join(PersonalKnowledgeService.base_dir, MEMORY_FILE)
    return "" unless File.exist?(abs)

    text = File.read(abs).to_s.strip
    return "" if text.blank?

    "# Long-term Memory\n\n## #{MEMORY_FILE}\n\n#{truncate(text, MEMORY_TRUNCATE_CHARS)}"
  rescue StandardError
    ""
  end

  # Backwards-compatible entry point.
  # Previously this performed QMD recall; it now returns curated memory only.
  def self.recall_for(_query)
    memory_context
  end

  def self.chat_context
    [core_context, memory_context].reject(&:blank?).join("\n\n---\n\n")
  end

  def self.truncate(s, max)
    t = s.to_s
    return t if t.length <= max

    t[0, max].rstrip + "…"
  end
end

# frozen_string_literal: true

require "yaml"
require "fileutils"

class PersonalKnowledgeService
  class Error < StandardError; end

  DEFAULT_BASE_DIR = File.expand_path("~/.pi/knowledge").freeze
  LEGACY_SYMLINK = File.expand_path("~/.pi/knowlege").freeze

  def self.base_dir
    File.expand_path(ENV.fetch("PI_KNOWLEDGE_DIR", DEFAULT_BASE_DIR))
  end

  def self.ensure_setup!
    FileUtils.mkdir_p(base_dir)
    FileUtils.mkdir_p(File.join(base_dir, "daily"))
    FileUtils.mkdir_p(File.join(base_dir, "topics"))
    FileUtils.mkdir_p(File.join(base_dir, "snippets"))

    readme = File.join(base_dir, "README.md")
    unless File.exist?(readme)
      File.write(readme, <<~MD)
        # Personal Knowledge Base (pi)

        This directory is a **long-lived**, **searchable** knowledge base for the pi coding agent.

        - Path: `~/.pi/knowledge` (symlinked from `~/.pi/knowlege` for convenience)
        - Search/index: QMD (`qmd search`, `qmd query`, `qmd update`, `qmd embed`)

        ## Conventions

        - Keep notes compact (OpenCLAW-style: TL;DR → key files → patterns/gotchas → examples → sources).
        - Knowledge changes over time: update existing notes instead of adding duplicates.
        - Avoid secrets.

        ## Core files

        - `SOUL.md` – assistant persona + boundaries
        - `IDENTITY.md` – assistant identity fields (name/vibe/emoji)
        - `USER.md` – your profile + preferences
        - `TOOLS.md` – environment-specific notes
        - `MEMORY.md` – curated long-term memory (keep short)
      MD
    end

    ensure_core_files!

    ensure_legacy_symlink!
  end

  CORE_FILES = {
    "SOUL.md" => <<~MD,
      # SOUL.md - Persona & Boundaries

      Keep replies concise and direct.
      Avoid generic filler. Have opinions when appropriate.

      Update this file when you learn better ways to help.
    MD
    "IDENTITY.md" => <<~MD,
      # IDENTITY.md - Agent Identity

      - Name: Gotar Bot
      - Creature: coding assistant
      - Vibe: concise, pragmatic, honest
      - Emoji: 🤖
    MD
    "USER.md" => <<~MD,
      # USER.md - User Profile

      - Name:
      - What to call you:
      - Timezone:
      - Notes:

      ## Preferences

      - 

      ## Projects / current context

      - 
    MD
    "TOOLS.md" => <<~MD,
      # TOOLS.md - Local Notes

      Put environment-specific notes here (hosts, paths, conventions).

      - 
    MD
    "MEMORY.md" => <<~MD,
      # MEMORY.md - Curated Long-Term Memory

      Keep this file compact. Prefer durable facts, decisions, and stable preferences.

      - 
    MD
  }.freeze

  def self.ensure_core_files!
    CORE_FILES.each do |name, content|
      path = File.join(base_dir, name)
      next if File.exist?(path)

      File.write(path, content)
    end
  end

  def self.ensure_legacy_symlink!
    return if File.symlink?(LEGACY_SYMLINK) && File.realpath(LEGACY_SYMLINK) == File.realpath(base_dir)

    # If a real dir/file exists at legacy path, don't clobber it.
    if File.exist?(LEGACY_SYMLINK) && !File.symlink?(LEGACY_SYMLINK)
      return
    end

    FileUtils.rm_f(LEGACY_SYMLINK)
    FileUtils.ln_s(base_dir, LEGACY_SYMLINK)
  rescue StandardError
    # Best-effort; ignore if filesystem disallows it.
    nil
  end

  def self.stats
    ensure_setup!

    {
      base_dir: base_dir,
      topics_count: Dir.glob(File.join(base_dir, "topics", "**", "*.md")).count,
      daily_count: Dir.glob(File.join(base_dir, "daily", "**", "*.md")).count,
      updated_at: latest_mtime
    }
  end

  def self.latest_mtime
    files = Dir.glob(File.join(base_dir, "**", "*.md"))
    return nil if files.empty?

    files.map { |f| File.mtime(f) }.max
  end

  def self.list(kind:, limit: 50)
    ensure_setup!

    sub = case kind.to_s
          when "topics" then "topics"
          when "daily" then "daily"
          when "snippets" then "snippets"
          else
            raise Error, "Unknown kind: #{kind}"
          end

    files = Dir.glob(File.join(base_dir, sub, "**", "*.md"))
      .sort_by { |p| -File.mtime(p).to_i }
      .first(limit)

    files.map { |abs| describe_file(abs) }
  end

  def self.describe_file(abs_path)
    rel = relative_path(abs_path)
    content = File.read(abs_path)
    fm = frontmatter(content)

    {
      path: rel,
      title: fm["title"].presence || guess_title(content, abs_path),
      updated_at: File.mtime(abs_path),
      created_at: fm["created"],
      tags: parse_tags(fm["tags"]),
      status: fm["status"],
      version: fm["version"]
    }
  rescue StandardError
    { path: relative_path(abs_path), title: File.basename(abs_path), updated_at: File.mtime(abs_path) }
  end

  def self.read(rel_path)
    abs = resolve_rel!(rel_path)
    File.read(abs)
  end

  def self.write(rel_path, content)
    abs = resolve_rel!(rel_path)
    File.write(abs, content)
    touch_updated_frontmatter!(abs)
  end

  # Merge new information into an existing note (preferred over creating duplicates).
  #
  # Strategy (keep notes compact):
  # - Add a dated bullet under "## Important patterns / gotchas" when possible.
  # - Update frontmatter tags/source/version when missing.
  # - Touch updated date.
  def self.merge_into!(rel_path, update_text:, tags: [], source: nil, version: nil)
    abs = resolve_rel!(rel_path)

    text = File.read(abs)

    update = build_update_block(update_text)

    marker = "## Important patterns / gotchas"
    if text.include?(marker)
      start = text.index(marker)
      # find end of section (next h2)
      after_marker = start + marker.length
      section_end = text.index("\n## ", after_marker) || text.length

      before = text[0...section_end].rstrip
      after = text[section_end..]

      text = before + "\n\n" + update + "\n\n" + after.to_s.lstrip
    else
      text = text.rstrip + "\n\n" + marker + "\n\n" + update + "\n"
    end

    text = merge_frontmatter(text, tags: tags, source: source, version: version)

    File.write(abs, text)
    touch_updated_frontmatter!(abs)

    relative_path(abs)
  end

  def self.create_topic!(title:, body:, tags: [], source: nil, version: nil)
    ensure_setup!

    slug = slugify(title)
    abs = File.join(base_dir, "topics", "#{slug}.md")

    if File.exist?(abs)
      # Update instead of overwrite; append new body.
      existing = File.read(abs)
      merged = existing.rstrip + "\n\n" + body.to_s.strip + "\n"
      File.write(abs, merged)
      touch_updated_frontmatter!(abs)
      return relative_path(abs)
    end

    now = Date.current.to_s
    fm = {
      "title" => title,
      "created" => now,
      "updated" => now,
      "status" => "active",
      "version" => version.to_s.presence,
      "tags" => tags,
      "source" => source.to_s.presence
    }.compact

    content = "---\n" + fm.to_yaml.sub(/\A---\s*\n?/, "") + "---\n\n" +
      "# #{title}\n\n" +
      "## TL;DR\n\n- \n\n" +
      "## Key files / locations\n\n- \n\n" +
      "## Important patterns / gotchas\n\n- \n\n" +
      "## Examples\n\n" +
      (body.to_s.strip.presence ? body.to_s.strip + "\n\n" : "") +
      "## Deprecated / history (keep tiny)\n\n- \n\n" +
      "## See also / sources\n\n" +
      (source.to_s.strip.presence ? "- #{source}\n" : "- \n")

    File.write(abs, content)
    relative_path(abs)
  end

  def self.slugify(s)
    s.to_s.downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/-+/, "-")
      .gsub(/\A-|-\z/, "")
      .presence || "note"
  end

  def self.resolve_rel!(rel_path)
    ensure_setup!

    rel = rel_path.to_s
    raise Error, "Missing path" if rel.blank?

    # Disallow absolute paths and traversal.
    clean = rel.sub(%r{\A/+}, "")
    raise Error, "Invalid path" if clean.include?("..")

    abs = File.expand_path(File.join(base_dir, clean))
    base = File.expand_path(base_dir)

    raise Error, "Path outside knowledge base" unless abs.start_with?(base + File::SEPARATOR) || abs == base
    raise Error, "Not a markdown file" unless abs.end_with?(".md")
    raise Error, "File not found" unless File.exist?(abs)

    abs
  end

  def self.relative_path(abs_path)
    Pathname.new(abs_path).relative_path_from(Pathname.new(base_dir)).to_s
  end

  def self.frontmatter(text)
    return {} unless text.start_with?("---\n")

    idx = text.index("\n---\n", 4)
    return {} unless idx

    yaml = text[4...idx]
    YAML.safe_load(yaml, permitted_classes: [Date], aliases: true) || {}
  rescue StandardError
    {}
  end

  def self.touch_updated_frontmatter!(abs)
    text = File.read(abs)
    return unless text.start_with?("---\n")

    idx = text.index("\n---\n", 4)
    return unless idx

    yaml = text[4...idx]
    rest = text[(idx + 5)..]

    fm = YAML.safe_load(yaml, permitted_classes: [Date], aliases: true) || {}
    fm["updated"] = Date.current.to_s

    out = "---\n" + fm.to_yaml.sub(/\A---\s*\n?/, "") + "---\n" + rest
    File.write(abs, out)
  rescue StandardError
    # best effort
    nil
  end

  def self.build_update_block(update_text)
    clean = update_text.to_s.strip
    date = Date.current.to_s

    return "- **Update #{date}**: (no details)" if clean.blank?

    lines = clean.lines.map { |l| l.strip }.reject(&:blank?)

    if lines.length == 1 && !lines.first.start_with?("-", "*")
      return "- **Update #{date}**: #{lines.first}"
    end

    out = ["- **Update #{date}**:"]
    lines.each do |l|
      l = l.sub(/\A[-*]\s+/, "")
      out << "  - #{l}"
    end

    out.join("\n")
  end

  def self.merge_frontmatter(text, tags: [], source: nil, version: nil)
    return text unless text.start_with?("---\n")

    idx = text.index("\n---\n", 4)
    return text unless idx

    yaml = text[4...idx]
    rest = text[(idx + 5)..]

    fm = YAML.safe_load(yaml, permitted_classes: [Date], aliases: true) || {}

    incoming_tags = Array(tags).map(&:to_s).reject(&:blank?)
    if incoming_tags.any?
      merged = (parse_tags(fm["tags"]) + incoming_tags).map(&:to_s).reject(&:blank?).uniq
      fm["tags"] = merged
    end

    if source.to_s.strip.present? && fm["source"].to_s.strip.blank?
      fm["source"] = source.to_s.strip
    end

    if version.to_s.strip.present? && fm["version"].to_s.strip.blank?
      fm["version"] = version.to_s.strip
    end

    "---\n" + fm.to_yaml.sub(/\A---\s*\n?/, "") + "---\n" + rest
  rescue StandardError
    text
  end

  def self.guess_title(content, abs_path)
    line = content.lines.find { |l| l.start_with?("# ") }
    return line.to_s.sub(/^#\s+/, "").strip if line.present?

    File.basename(abs_path, ".md").tr("_", " ").tr("-", " ").split.map(&:capitalize).join(" ")
  end

  def self.parse_tags(tags)
    case tags
    when Array then tags
    when String then tags.split(/[,\s]+/).reject(&:blank?)
    else []
    end
  end
end

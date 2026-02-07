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
      MD
    end

    ensure_legacy_symlink!
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

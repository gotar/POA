# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"
require "time"

# Imports pi TUI session logs (JSONL) from ~/.pi/agent/sessions into the
# personal knowledge vault as Markdown, so QMD can index/search them.
#
# Also provides lightweight signal extraction so living-doc polish can learn from
# TUI sessions (preference quotes, bash commands, errors).
class PiSessionImportService
  DEFAULT_SESSIONS_DIR = File.expand_path("~/.pi/agent/sessions").freeze
  DEST_REL_DIR = File.join("snippets", "pi-sessions").freeze

  MAX_DOC_CHARS = ENV.fetch("PI_SESSION_IMPORT_MAX_DOC_CHARS", "80000").to_i
  MAX_ENTRIES = ENV.fetch("PI_SESSION_IMPORT_MAX_ENTRIES", "800").to_i

  INCLUDE_TOOL_RESULTS = ENV.fetch("PI_SESSION_IMPORT_INCLUDE_TOOL_RESULTS", "false") == "true"
  TOOL_RESULT_MAX_CHARS = ENV.fetch("PI_SESSION_IMPORT_TOOL_RESULT_MAX_CHARS", "800").to_i

  class << self
    def sessions_dir
      File.expand_path(ENV.fetch("PI_SESSIONS_DIR", DEFAULT_SESSIONS_DIR))
    end

    def dest_dir
      File.join(PersonalKnowledgeService.base_dir, DEST_REL_DIR)
    end

    def session_files
      base = sessions_dir
      return [] unless Dir.exist?(base)

      Dir.glob(File.join(base, "**", "*.jsonl"))
    end

    # Best-effort import. Writes/updates Markdown files under:
    #   ~/.pi/knowledge/snippets/pi-sessions/<same structure as ~/.pi/agent/sessions>/...md
    def import!(since: nil, limit: nil)
      PersonalKnowledgeService.ensure_setup!

      base = sessions_dir
      unless Dir.exist?(base)
        return { imported: 0, updated: 0, skipped: 0, errors: ["sessions_dir_missing: #{base}"] }
      end

      paths = session_files.sort_by { |p| File.mtime(p).to_i }

      if since
        since_t = parse_time(since)
        paths.select! { |p| File.mtime(p) >= since_t } if since_t
      end

      lim = limit.to_i
      paths = paths.last(lim) if lim.positive?

      stats = { imported: 0, updated: 0, skipped: 0, errors: [] }

      paths.each do |src|
        rel = Pathname.new(src).relative_path_from(Pathname.new(base)).to_s
        dst = File.join(dest_dir, rel).sub(/\.jsonl\z/, ".md")
        FileUtils.mkdir_p(File.dirname(dst))

        existed = File.exist?(dst)
        if existed && File.mtime(dst) >= File.mtime(src)
          stats[:skipped] += 1
          next
        end

        md = build_markdown(src, rel_path: rel)
        File.write(dst, md)

        existed ? stats[:updated] += 1 : stats[:imported] += 1
      rescue StandardError => e
        stats[:errors] << "#{rel}: #{e.class}: #{e.message}"
      end

      RuntimeMetric.set("pi_sessions.import_last_run_at", Time.current.iso8601) rescue nil
      RuntimeMetric.set("pi_sessions.import_last_summary", stats.to_json) rescue nil

      stats
    end

    # Extract signals from pi TUI sessions since a time.
    # Returns { preference_quotes:, recent_bash_commands:, recent_errors: }
    def extract_signals(since:, max_preference_quotes: 40, max_bash_commands: 25, max_errors: 30)
      base = sessions_dir
      return { preference_quotes: [], recent_bash_commands: [], recent_errors: [] } unless Dir.exist?(base)

      since_t = parse_time(since)
      pref_rx = /(my name is|call me|timezone|i prefer|i like|i don't like|i do not like|remember that|note that|always|never)/i

      preference_quotes = []
      bash_commands = []
      errors = []

      session_files.sort_by { |p| File.mtime(p).to_i }.each do |path|
        next if since_t && File.mtime(path) < since_t

        File.foreach(path) do |line|
          ev = parse_json_line(line)
          next unless ev.is_a?(Hash)

          next unless ev["type"].to_s == "message"
          msg = ev["message"]
          next unless msg.is_a?(Hash)

          role = msg["role"].to_s

          if role == "user"
            txt = extract_text_from_blocks(msg["content"])
            txt = sanitize_text(txt)
            next if txt.blank?

            txt.lines.map(&:strip).each do |l|
              next if l.blank?
              if l.match?(pref_rx)
                preference_quotes << l
                break if preference_quotes.length >= max_preference_quotes
              end
            end
          end

          if role == "assistant"
            if msg["stopReason"].to_s == "error" || msg["errorMessage"].present?
              em = msg["errorMessage"].to_s
              em = "assistant_error" if em.blank?
              errors << one_line(em)
              break if errors.length >= max_errors
            end

            tool_calls = extract_tool_calls_from_blocks(msg["content"])
            tool_calls.each do |tc|
              next unless tc[:name] == "bash"
              bash_commands << tc[:command]
              break if bash_commands.length >= max_bash_commands
            end
          end

          if role == "toolResult" && msg["isError"]
            tname = msg["toolName"].to_s
            txt = extract_text_from_blocks(msg["content"])
            txt = sanitize_text(txt)
            next if txt.blank?
            errors << "#{tname}: #{one_line(txt)}"
            break if errors.length >= max_errors
          end

          break if preference_quotes.length >= max_preference_quotes && bash_commands.length >= max_bash_commands && errors.length >= max_errors
        end

        break if preference_quotes.length >= max_preference_quotes && bash_commands.length >= max_bash_commands && errors.length >= max_errors
      rescue StandardError
        next
      end

      {
        preference_quotes: preference_quotes.uniq.first(max_preference_quotes),
        recent_bash_commands: bash_commands.uniq.first(max_bash_commands),
        recent_errors: errors.uniq.first(max_errors)
      }
    end

    private

    def build_markdown(src_path, rel_path:)
      session_meta = {}
      entries = []
      chars_used = 0

      File.open(src_path, "r") do |f|
        header = parse_json_line(f.gets)
        session_meta = header if header.is_a?(Hash) && header["type"].to_s == "session"

        f.each_line do |line|
          ev = parse_json_line(line)
          next unless ev.is_a?(Hash)

          case ev["type"].to_s
          when "model_change"
            provider = ev["provider"].to_s
            model = ev["modelId"].to_s
            append_entry!(entries, "**Model:** #{provider}/#{model}", chars_used)
            chars_used = entries_chars(entries)
          when "message"
            msg = ev["message"]
            next unless msg.is_a?(Hash)

            role = msg["role"].to_s

            case role
            when "user"
              txt = sanitize_text(extract_text_from_blocks(msg["content"]))
              next if txt.blank?
              append_entry!(entries, "**User:** #{one_line(txt)}", chars_used)
              chars_used = entries_chars(entries)

            when "assistant"
              if msg["stopReason"].to_s == "error" || msg["errorMessage"].present?
                em = msg["errorMessage"].to_s
                em = "assistant_error" if em.blank?
                append_entry!(entries, "**Assistant (error):** #{one_line(em)}", chars_used)
                chars_used = entries_chars(entries)
                next
              end

              extract_tool_calls_from_blocks(msg["content"]).each do |tc|
                append_entry!(entries, "**Tool call (#{tc[:name]}):** #{tc[:summary]}", chars_used)
                chars_used = entries_chars(entries)
              end

              txt = sanitize_text(extract_text_from_blocks(msg["content"]))
              append_entry!(entries, "**Assistant:** #{one_line(txt)}", chars_used) if txt.present?
              chars_used = entries_chars(entries)

            when "toolResult"
              next unless INCLUDE_TOOL_RESULTS

              tool = msg["toolName"].to_s
              txt = sanitize_text(extract_text_from_blocks(msg["content"]))
              next if txt.blank?

              txt = txt[0, TOOL_RESULT_MAX_CHARS] + "…" if txt.length > TOOL_RESULT_MAX_CHARS
              flag = msg["isError"] ? " error" : ""
              append_entry!(entries, "**Tool result (#{tool}#{flag}):** #{one_line(txt)}", chars_used)
              chars_used = entries_chars(entries)
            end
          end

          break if entries.length >= MAX_ENTRIES
          break if chars_used >= MAX_DOC_CHARS
        end
      end

      ts = session_meta["timestamp"].to_s
      cwd = session_meta["cwd"].to_s
      sid = session_meta["id"].to_s

      title_ts = ts.presence || File.basename(src_path, ".jsonl")

      fm = {
        "title" => "Pi session #{title_ts}",
        "source" => "pi-tui",
        "session_id" => sid.presence || File.basename(src_path, ".jsonl"),
        "cwd" => cwd.presence,
        "created" => (ts[0, 10] rescue nil),
        "updated" => Date.current.to_s,
        "path" => rel_path
      }.compact

      out = +"---\n"
      out << fm.to_yaml.sub(/\A---\s*\n?/, "")
      out << "---\n\n"

      out << "# Pi session\n\n"
      out << "- Timestamp: `#{ts}`\n" if ts.present?
      out << "- CWD: `#{cwd}`\n" if cwd.present?
      out << "- Source log: `#{rel_path}`\n\n"

      out << "## Transcript\n\n"
      if entries.empty?
        out << "_(No transcript entries captured.)_\n"
      else
        out << entries.join("\n\n")
        out << "\n"
      end

      out
    end

    def append_entry!(entries, entry, chars_used)
      return if entry.to_s.strip.blank?
      return if entries.length >= MAX_ENTRIES

      projected = chars_used + entry.length + 2
      if projected > MAX_DOC_CHARS
        entries << "_(truncated)_" unless entries.last.to_s.include?("truncated")
        return
      end

      entries << entry
    end

    def entries_chars(entries)
      # cheap-ish: called at most MAX_ENTRIES; keep it simple.
      entries.sum { |e| e.to_s.length + 2 }
    end

    def parse_json_line(line)
      return nil if line.nil?
      JSON.parse(line)
    rescue JSON::ParserError
      nil
    end

    def parse_time(v)
      return v if v.is_a?(Time)
      return nil if v.blank?

      Time.parse(v.to_s)
    rescue StandardError
      nil
    end

    def extract_text_from_blocks(content)
      return "" unless content.is_a?(Array)

      content.filter_map do |block|
        next unless block.is_a?(Hash)
        next if block["type"].to_s == "thinking"
        next unless block["type"].to_s == "text"

        block["text"].to_s
      end.join("\n").strip
    end

    def extract_tool_calls_from_blocks(content)
      return [] unless content.is_a?(Array)

      content.filter_map do |block|
        next unless block.is_a?(Hash)
        next unless block["type"].to_s == "toolCall"

        name = block["name"].to_s
        args = block["arguments"].is_a?(Hash) ? block["arguments"] : {}

        if name == "bash"
          cmd = args["command"].to_s.strip
          next if cmd.blank?
          {
            name: name,
            command: cmd,
            summary: "`#{cmd[0, 220]}#{cmd.length > 220 ? "…" : ""}`"
          }
        else
          summary = summarize_tool_call(name, args)
          { name: name, summary: summary }
        end
      end
    end

    def summarize_tool_call(name, args)
      case name
      when "read"
        p = args["path"].to_s
        p.present? ? "path=\`#{p}\`" : "(no args)"
      when "ls"
        p = args["path"].to_s
        p.present? ? "path=\`#{p}\`" : "(no args)"
      when "grep"
        pat = args["pattern"].to_s
        p = args["path"].to_s
        out = []
        out << "pattern=\`#{pat}\`" if pat.present?
        out << "path=\`#{p}\`" if p.present?
        out.join(" ").presence || "(no args)"
      else
        s = args.to_json
        s = s[0, 240] + "…" if s.length > 240
        s
      end
    end

    def one_line(text)
      text.to_s.gsub(/\s+/, " ").strip
    end

    def sanitize_text(text)
      t = text.to_s

      # Basic redactions (best-effort)
      t = t.gsub(/sk-[A-Za-z0-9]{20,}/, "sk-REDACTED")
      t = t.gsub(/(?i)authorization:\s*bearer\s+[A-Za-z0-9._-]{10,}/, "Authorization: Bearer REDACTED")
      t = t.gsub(/-----BEGIN [^-]*PRIVATE KEY-----(.*?)-----END [^-]*PRIVATE KEY-----/m, "[REDACTED_PRIVATE_KEY]")

      t
    end
  end
end

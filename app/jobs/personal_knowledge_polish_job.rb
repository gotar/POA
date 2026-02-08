# frozen_string_literal: true

require "fileutils"

# PersonalKnowledgePolishJob
#
# Daily (or manual) job that rewrites core "living docs" in ~/.pi/knowledge
# (SOUL/IDENTITY/USER/TOOLS/MEMORY) based on recent chat signals.
#
# NOTE: This is intentionally NOT a draft/approve flow per user request.
# It writes backups before applying changes.
class PersonalKnowledgePolishJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "personal_knowledge.polish_lock"

  CORE_FILES = %w[SOUL.md IDENTITY.md USER.md TOOLS.md MEMORY.md].freeze

  MAX_FILE_CHARS = {
    "SOUL.md" => 2_200,
    "IDENTITY.md" => 1_000,
    "USER.md" => 3_000,
    "TOOLS.md" => 3_000,
    "MEMORY.md" => 4_500
  }.freeze

  def perform
    started_at = Time.current

    LeaseLock.with_lock(key: LOCK_KEY, wait_seconds: 0, lease_minutes: 120) do
      PersonalKnowledgeService.ensure_setup!

      base_dir = PersonalKnowledgeService.base_dir
      current = CORE_FILES.to_h do |name|
        abs = File.join(base_dir, name)
        [name, File.exist?(abs) ? File.read(abs).to_s : ""]
      end

      since = RuntimeMetric.time("personal_knowledge.polish_last_run_at") || 24.hours.ago
      signals = collect_signals(since: since)

      prompt = build_prompt(current: current, signals: signals)
      provider, model = resolve_polish_model
      output = run_pi(prompt, provider: provider, model: model)

      updates = CORE_FILES.to_h { |name| [name, extract_block(output, name)] }

      backup_dir = File.join(base_dir, "snippets", "living-docs-backups")
      FileUtils.mkdir_p(backup_dir)

      applied = []
      skipped = []

      CORE_FILES.each do |name|
        next_text = updates[name].to_s
        if next_text.blank?
          skipped << { file: name, reason: "missing_output" }
          next
        end

        unless next_text.include?(name)
          skipped << { file: name, reason: "missing_header" }
          next
        end

        max_chars = MAX_FILE_CHARS[name] || 4_000
        if next_text.length > max_chars
          skipped << { file: name, reason: "too_long", length: next_text.length, max: max_chars }
          next
        end

        abs = File.join(base_dir, name)
        if File.exist?(abs)
          ts = started_at.strftime("%Y%m%d-%H%M%S")
          backup_path = File.join(backup_dir, "#{ts}-#{name}")
          File.write(backup_path, File.read(abs)) rescue nil
        end

        File.write(abs, next_text.rstrip + "\n")
        applied << name
      end

      RuntimeMetric.set("personal_knowledge.polish_last_run_at", started_at.iso8601)
      RuntimeMetric.set("personal_knowledge.polish_last_status", "ok")
      RuntimeMetric.set(
        "personal_knowledge.polish_last_summary",
        { applied: applied, skipped: skipped, provider: provider, model: model }.to_json
      )
    end
  rescue LeaseLock::Busy
    RuntimeMetric.set("personal_knowledge.polish_last_status", "skipped_busy") rescue nil
  rescue StandardError => e
    RuntimeMetric.set("personal_knowledge.polish_last_run_at", Time.current.iso8601) rescue nil
    RuntimeMetric.set("personal_knowledge.polish_last_status", "error") rescue nil
    RuntimeMetric.set("personal_knowledge.polish_last_summary", { error: "#{e.class}: #{e.message}" }.to_json) rescue nil
    raise
  end

  private

  def resolve_polish_model
    provider = ENV["PI_POLISH_PROVIDER"].to_s.strip
    model = ENV["PI_POLISH_MODEL"].to_s.strip

    if provider.present? && model.present?
      return [provider, model]
    end

    defaults = PiModelsService.default_provider_model
    [defaults[:provider], defaults[:model]]
  rescue StandardError
    [ENV["PI_PROVIDER"].to_s, ENV["PI_MODEL"].to_s]
  end

  def collect_signals(since:)
    signals = {}

    # Recent user messages (raw quotes). Keep short to avoid token blowups.
    recent_user = Message.where(role: "user").where("created_at >= ?", since).order(:created_at).last(80)
    signals[:recent_user_messages] = recent_user.map do |m|
      t = m.created_at.in_time_zone.strftime("%F %H:%M")
      txt = m.content.to_s.strip.gsub(/\s+/, " ")
      txt = txt[0, 280] + "…" if txt.length > 280
      "[#{t}] #{txt}"
    end

    # Preference signals: only include lines that look like real preferences (avoid hallucinations).
    pref_rx = /(my name is|call me|timezone|i prefer|i like|i don't like|i do not like|remember that|note that|always|never)/i
    signals[:preference_quotes] = recent_user.map(&:content).join("\n").lines.map(&:strip).select { |l| l.match?(pref_rx) }.uniq.first(30)

    # Recent tool usage (bash commands)
    recent_tools = MessageToolCall.where("created_at >= ?", since).order(:created_at).last(60)
    bash_cmds = recent_tools.filter_map do |tc|
      next unless tc.tool_name.to_s == "bash"
      cmd = (tc.args || {})["command"] rescue nil
      cmd = cmd.to_s.strip
      next if cmd.blank?
      cmd = cmd[0, 180] + "…" if cmd.length > 180
      cmd
    end
    signals[:recent_bash_commands] = bash_cmds.uniq.first(25)

    # Recent errors
    recent_errors = Message.where(status: "error").where("created_at >= ?", since).order(:created_at).last(30)
    signals[:recent_errors] = recent_errors.map do |m|
      t = m.created_at.in_time_zone.strftime("%F %H:%M")
      "[#{t}] #{m.role}: #{m.content.to_s.strip.gsub(/\s+/, " ")[0, 200]}"
    end

    # Also learn from pi TUI sessions (JSONL logs) so living docs reflect work done
    # outside of the web UI.
    begin
      pi = PiSessionImportService.extract_signals(since: since)
      signals[:preference_quotes] = (Array(signals[:preference_quotes]) + Array(pi[:preference_quotes])).uniq.first(40)
      signals[:recent_bash_commands] = (Array(signals[:recent_bash_commands]) + Array(pi[:recent_bash_commands])).uniq.first(40)
      signals[:recent_errors] = (Array(signals[:recent_errors]) + Array(pi[:recent_errors])).uniq.first(40)
    rescue StandardError => e
      signals[:pi_sessions_error] = "#{e.class}: #{e.message}"
    end

    signals
  rescue StandardError => e
    { error: "signal_collection_failed: #{e.class}: #{e.message}" }
  end

  def build_prompt(current:, signals:)
    env_facts = {
      app: {
        repo: "/home/gotar/pi-web-ui",
        url: "https://bot.gotar.info/",
        services: ["gotar-bot-web (puma 3090)", "gotar-bot-jobs (solid_queue)"],
        knowledge_dir: PersonalKnowledgeService.base_dir,
        qmd_bin: ENV.fetch("QMD_BIN", "qmd"),
        qmd_collection: ENV.fetch("PI_KNOWLEDGE_QMD_COLLECTION", "pi-knowledge")
      }
    }

    <<~PROMPT
      You maintain 5 living docs used as the ONLY memory context during chat turns:
      - SOUL.md (persona/boundaries)
      - IDENTITY.md (identity fields)
      - USER.md (user profile + preferences)
      - TOOLS.md (local environment notes)
      - MEMORY.md (curated long-term memory)

      Goal: produce polished, compact, non-redundant versions of these files.

      HARD RULES:
      1) Do NOT invent facts. Only incorporate information explicitly present in the inputs (current files + recent quotes).
      2) If you are not sure about something, leave it unchanged.
      3) Keep each file SHORT and practical. Avoid fluff.
      4) Do not add new sections unless necessary.
      5) DO NOT output any text outside the required markers.

      OUTPUT FORMAT (exactly these 5 blocks, in this order):
      =====BEGIN SOUL.md=====
      <full file content>
      =====END SOUL.md=====
      ... same for IDENTITY.md, USER.md, TOOLS.md, MEMORY.md

      INPUTS:

      # Environment facts (trusted)
      #{JSON.pretty_generate(env_facts)}

      # Recent preference quotes (trusted raw snippets)
      #{Array(signals[:preference_quotes]).map { |l| "- #{l}" }.join("\n")}

      # Recent bash commands (may include one-offs; only keep stable ones in TOOLS.md)
      #{Array(signals[:recent_bash_commands]).map { |l| "- #{l}" }.join("\n")}

      # Recent errors (for improving TOOLS.md troubleshooting notes)
      #{Array(signals[:recent_errors]).map { |l| "- #{l}" }.join("\n")}

      # CURRENT FILES (treat as source of truth)
      ---
      #{current.map { |name, text| "## #{name}\n\n" + text.to_s.strip }.join("\n\n---\n\n")}
      ---

      Now output the updated files.
    PROMPT
  end

  def run_pi(prompt, provider:, model:)
    buffer = +""
    final = nil

    PiRpcPool.with_client(provider: provider, model: model) do |pi|
      pi.prompt(prompt) do |event|
        case event["type"]
        when "message_update"
          ev = event["assistantMessageEvent"]
          next unless ev.is_a?(Hash)
          next unless ev["type"] == "text_delta"

          delta = ev["delta"].to_s
          buffer << delta if delta.present?
        when "agent_end"
          final = buffer

          # Safety fallback: agent_end includes full messages
          if final.to_s.strip.blank? && event["messages"].is_a?(Array)
            last_assistant = event["messages"].reverse.find { |m| m.is_a?(Hash) && m["role"] == "assistant" }
            if last_assistant&.dig("content").is_a?(Array)
              final = extract_text_from_content(last_assistant["content"])
            end
          end
        end
      end
    end

    (final.presence || buffer).to_s
  end

  def extract_text_from_content(content)
    return "" unless content.is_a?(Array)

    text_parts = content.filter_map do |block|
      next unless block.is_a?(Hash)
      next if block["type"].to_s == "thinking"

      if block["type"].to_s == "text"
        t = block["text"].to_s
        t.presence
      end
    end

    text_parts.join("\n").strip
  end

  def extract_block(text, name)
    start = "=====BEGIN #{name}====="
    endm = "=====END #{name}====="

    i = text.index(start)
    return "" unless i

    j = text.index(endm, i + start.length)
    return "" unless j

    inner = text[(i + start.length)..(j - 1)].to_s
    inner.strip
  end
end

# frozen_string_literal: true

require "net/imap"
require "open3"

class SystemHeartbeatJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  LOCK_KEY = "heartbeat.lock"

  SCHEDULER_STALE_SECONDS = ENV.fetch("HEARTBEAT_SCHEDULER_STALE_SECONDS", "180").to_i
  CONVERSATION_STUCK_SECONDS = ENV.fetch("HEARTBEAT_CONVERSATION_STUCK_SECONDS", "1200").to_i
  FAILED_JOBS_WINDOW_HOURS = ENV.fetch("HEARTBEAT_FAILED_JOBS_WINDOW_HOURS", "24").to_i
  FAILED_JOBS_THRESHOLD = ENV.fetch("HEARTBEAT_FAILED_JOBS_THRESHOLD", "1").to_i

  # Heartbeat options are dynamic:
  # - defaults come from ENV
  # - UI toggles are stored in runtime_metrics

  def perform
    started_at = Time.current

    LeaseLock.with_lock(key: LOCK_KEY, wait_seconds: 0, lease_minutes: 10) do
      alerts = []

      scheduler_tick = check_scheduler_tick!(alerts: alerts, now: started_at)
      failed_jobs = check_failed_jobs!(alerts: alerts)
      check_binaries!(alerts: alerts)
      check_gmail_unseen!(alerts: alerts)

      fixed = recover_stuck_conversations!(now: started_at)
      if fixed[:stuck_conversations].positive?
        alerts << "Recovered stuck conversations: #{fixed[:stuck_conversations]} (messages fixed: #{fixed[:stuck_messages]}, tool calls fixed: #{fixed[:stuck_tool_calls]})"
      end

      agent_res = run_agent_heartbeat_if_needed!(
        now: started_at,
        scheduler_tick: scheduler_tick,
        failed_jobs: failed_jobs,
        stuck_fixed: fixed
      )

      if agent_res[:status] == "alert"
        alerts << "Agent heartbeat: #{agent_res[:message]}"
      elsif agent_res[:status] == "failed"
        alerts << "Agent heartbeat failed: #{agent_res[:error]}"
      end

      status = alerts.any? ? "alert" : "ok"
      duration_ms = ((Time.current - started_at) * 1000).to_i

      RuntimeMetric.set("heartbeat.last_run_at", started_at.iso8601)
      RuntimeMetric.set("heartbeat.last_status", status)
      RuntimeMetric.set("heartbeat.last_duration_ms", duration_ms.to_s)
      RuntimeMetric.set("heartbeat.last_alerts", alerts.to_json)

      record_heartbeat_event!(
        started_at: started_at,
        duration_ms: duration_ms,
        status: status,
        alerts: alerts,
        fixed: fixed,
        agent_res: agent_res
      )

      send_push_alerts!(status: status, alerts: alerts) if push_alerts_enabled? && status != "ok"

      # Opportunistic cleanup
      PiRpcPool.stop_idle! rescue nil
    end
  rescue LeaseLock::Busy
    # Another heartbeat is running; do nothing.
    RuntimeMetric.set("heartbeat.last_status", "skipped_busy") rescue nil
  rescue StandardError => e
    RuntimeMetric.set("heartbeat.last_run_at", Time.current.iso8601) rescue nil
    RuntimeMetric.set("heartbeat.last_status", "error") rescue nil
    RuntimeMetric.set("heartbeat.last_alerts", ["Heartbeat crashed: #{e.class}: #{e.message}"].to_json) rescue nil
    raise
  end

  private

  # ---------- Settings (ENV defaults + UI overrides) ----------

  def push_alerts_enabled?
    override = RuntimeMetric.get("heartbeat.push_alerts_enabled").to_s.strip
    return override == "true" if override.present?

    ENV.fetch("HEARTBEAT_PUSH_ALERTS", "false") == "true"
  rescue StandardError
    ENV.fetch("HEARTBEAT_PUSH_ALERTS", "false") == "true"
  end

  def agent_heartbeat_enabled?
    override = RuntimeMetric.get("heartbeat.agent_enabled").to_s.strip
    return override == "true" if override.present?

    ENV.fetch("HEARTBEAT_AGENT_ENABLED", "true") == "true"
  rescue StandardError
    ENV.fetch("HEARTBEAT_AGENT_ENABLED", "true") == "true"
  end

  def agent_heartbeat_skip_when_busy?
    override = RuntimeMetric.get("heartbeat.agent_skip_when_busy").to_s.strip
    return override == "true" if override.present?

    ENV.fetch("HEARTBEAT_AGENT_SKIP_WHEN_BUSY", "true") == "true"
  rescue StandardError
    ENV.fetch("HEARTBEAT_AGENT_SKIP_WHEN_BUSY", "true") == "true"
  end

  def agent_heartbeat_force?
    ENV.fetch("HEARTBEAT_AGENT_FORCE", "false") == "true"
  end

  def agent_heartbeat_ack_max_chars
    ENV.fetch("HEARTBEAT_AGENT_ACK_MAX_CHARS", "300").to_i
  end

  def gmail_heartbeat_enabled?
    override = RuntimeMetric.get("heartbeat.gmail_enabled").to_s.strip
    return override == "true" if override.present?

    ENV.fetch("HEARTBEAT_GMAIL_ENABLED", "true") == "true"
  rescue StandardError
    ENV.fetch("HEARTBEAT_GMAIL_ENABLED", "true") == "true"
  end

  def gmail_heartbeat_settings
    {
      user: ENV.fetch("HEARTBEAT_GMAIL_USER", "gotarbot@gmail.com"),
      host: ENV.fetch("HEARTBEAT_GMAIL_IMAP_HOST", "imap.gmail.com"),
      port: ENV.fetch("HEARTBEAT_GMAIL_IMAP_PORT", "993").to_i,
      folder: ENV.fetch("HEARTBEAT_GMAIL_FOLDER", "INBOX"),
      pass_cmd: ENV.fetch("HEARTBEAT_GMAIL_PASS_CMD", "pass show services/gmail/gotarbot | head -n 1")
    }
  end

  def check_scheduler_tick!(alerts:, now:)
    tick = RuntimeMetric.time("scheduled_jobs.last_tick_at")
    if tick.nil?
      alerts << "Scheduler tick metric missing (scheduled_jobs.last_tick_at)"
      return nil
    end

    if tick < now - SCHEDULER_STALE_SECONDS.seconds
      alerts << "Scheduler tick stale: last tick #{tick.iso8601} (#{((now - tick) / 60).round}m ago)"
    end

    tick
  end

  def check_failed_jobs!(alerts:)
    window_start = FAILED_JOBS_WINDOW_HOURS.hours.ago
    failed_recent = SolidQueue::Job.where(status: "failed").where("created_at >= ?", window_start).count
    if failed_recent >= FAILED_JOBS_THRESHOLD
      alerts << "Failed jobs in last #{FAILED_JOBS_WINDOW_HOURS}h: #{failed_recent}"
    end
    failed_recent
  rescue ActiveRecord::StatementInvalid
    # queue schema may not exist in dev/test
    nil
  end

  def check_binaries!(alerts:)
    now = Time.current

    qmd = ENV.fetch("QMD_BIN", "qmd").to_s
    pi = "pi"

    qmd_found = system("which", qmd, out: File::NULL, err: File::NULL)
    pi_found = system("which", pi, out: File::NULL, err: File::NULL)

    RuntimeMetric.set("diagnostics.qmd_binary", qmd_found ? "ok" : "missing") rescue nil
    RuntimeMetric.set("diagnostics.pi_binary", pi_found ? "ok" : "missing") rescue nil

    unless qmd_found
      alerts << "QMD binary not found in PATH: #{qmd}"
      RuntimeMetric.set("qmd.last_check_at", now.iso8601) rescue nil
      RuntimeMetric.set("qmd.last_status", "missing_binary") rescue nil
      RuntimeMetric.set("qmd.last_error", "qmd binary not found") rescue nil
      return
    end

    # Best-effort health check: `qmd status` (keep short so it doesn't compete with heavy ops)
    begin
      status_timeout = ENV.fetch("QMD_STATUS_TIMEOUT_SECONDS", "10").to_i
      text = QmdCliService.run!("status", timeout: status_timeout)
      excerpt = text.to_s.strip
      excerpt = excerpt[0, 1200] + "…" if excerpt.length > 1200

      RuntimeMetric.set("qmd.last_check_at", now.iso8601)
      RuntimeMetric.set("qmd.last_status", "ok")
      RuntimeMetric.set("qmd.last_status_excerpt", excerpt)
      RuntimeMetric.set("qmd.last_error", "")
    rescue StandardError => e
      alerts << "QMD unhealthy: #{e.message}"
      RuntimeMetric.set("qmd.last_check_at", now.iso8601) rescue nil
      RuntimeMetric.set("qmd.last_status", "error") rescue nil
      RuntimeMetric.set("qmd.last_error", "#{e.class}: #{e.message}") rescue nil
    end

    unless pi_found
      alerts << "pi binary not found in PATH"
    end
  rescue StandardError
    nil
  end

  def check_gmail_unseen!(alerts:)
    return unless gmail_heartbeat_enabled?

    settings = gmail_heartbeat_settings
    now = Time.current
    imap = nil

    password = fetch_pass_password(settings[:pass_cmd])
    if password.blank?
      RuntimeMetric.set("gmail.last_check_at", now.iso8601) rescue nil
      RuntimeMetric.set("gmail.last_status", "missing_password") rescue nil
      RuntimeMetric.set("gmail.last_error", "Empty password from pass") rescue nil
      alerts << "Gmail IMAP check failed: missing password"
      return
    end

    imap = Net::IMAP.new(settings[:host], port: settings[:port], ssl: true)
    imap.login(settings[:user], password)
    imap.select(settings[:folder])
    unseen = imap.search(["UNSEEN"]).count

    RuntimeMetric.set("gmail.unseen_count", unseen.to_s)
    RuntimeMetric.set("gmail.last_check_at", now.iso8601)
    RuntimeMetric.set("gmail.last_status", "ok")
    RuntimeMetric.set("gmail.last_error", "")

    alerts << "Gmail: #{unseen} unread message(s) in #{settings[:folder]}" if unseen.positive?
  rescue StandardError => e
    RuntimeMetric.set("gmail.last_check_at", now.iso8601) rescue nil
    RuntimeMetric.set("gmail.last_status", "error") rescue nil
    RuntimeMetric.set("gmail.last_error", "#{e.class}: #{e.message}") rescue nil
    alerts << "Gmail IMAP check failed: #{e.class}: #{e.message}"
  ensure
    begin
      imap.logout if imap
      imap.disconnect if imap
    rescue StandardError
      nil
    end
  end

  def fetch_pass_password(cmd)
    stdout, _stderr, status = Open3.capture3("bash", "-lc", cmd.to_s)
    return "" unless status.success?

    stdout.to_s.strip
  rescue StandardError
    ""
  end

  def recover_stuck_conversations!(now:)
    fixed = { stuck_conversations: 0, stuck_messages: 0, stuck_tool_calls: 0 }

    stuck_before = now - CONVERSATION_STUCK_SECONDS.seconds
    Conversation.where(processing: true)
      .where("processing_started_at IS NOT NULL AND processing_started_at < ?", stuck_before)
      .limit(25)
      .find_each do |conv|
        res = recover_stuck_conversation!(conv)
        fixed[:stuck_conversations] += 1 if res[:conversation_released]
        fixed[:stuck_messages] += res[:messages_fixed]
        fixed[:stuck_tool_calls] += res[:tool_calls_fixed]
      end

    fixed
  end

  def recover_stuck_conversation!(conversation)
    conversation_released = false
    messages_fixed = 0
    tool_calls_fixed = 0

    conversation.with_lock do
      return { conversation_released: false, messages_fixed: 0, tool_calls_fixed: 0 } unless conversation.processing?

      conversation.update!(processing: false, processing_started_at: nil)
      conversation_released = true
    end

    # Mark any still-running messages as error.
    running_messages = conversation.messages.where(status: "running")
    running_messages.find_each do |msg|
      next_content = msg.content.to_s
      if msg.role == "assistant" && next_content.strip.blank?
        next_content = "⏰ This run got stuck (heartbeat recovery). Please try again."
      elsif msg.role == "assistant" && !next_content.start_with?("❌", "⏰", "🔧")
        next_content = "⏰ #{next_content}".strip
      end

      msg.update!(status: "error", content: next_content)
      messages_fixed += 1

      Turbo::StreamsChannel.broadcast_replace_to(
        conversation,
        target: dom_id(msg),
        partial: "messages/message",
        locals: { message: msg }
      )
    rescue StandardError
      nil
    end

    # Mark any running tool calls as error.
    MessageToolCall.joins(:message)
      .where(messages: { conversation_id: conversation.id })
      .where(status: "running")
      .find_each do |tc|
        tc.update!(
          status: "error",
          is_error: true,
          ended_at: Time.current,
          output_text: (tc.output_text.presence || "Interrupted (heartbeat recovery).")
        )
        tool_calls_fixed += 1

        Turbo::StreamsChannel.broadcast_replace_to(
          conversation,
          target: "message_#{tc.message_id}_tools",
          partial: "messages/tool_calls",
          locals: { message: tc.message.reload }
        )
      rescue StandardError
        nil
      end

    { conversation_released: conversation_released, messages_fixed: messages_fixed, tool_calls_fixed: tool_calls_fixed }
  end

  def run_agent_heartbeat_if_needed!(now:, scheduler_tick:, failed_jobs:, stuck_fixed:)
    unless agent_heartbeat_enabled?
      RuntimeMetric.set("heartbeat.agent_last_run_at", now.iso8601)
      RuntimeMetric.set("heartbeat.agent_last_status", "skipped_disabled")
      RuntimeMetric.set("heartbeat.agent_last_provider", "")
      RuntimeMetric.set("heartbeat.agent_last_model", "")
      RuntimeMetric.set("heartbeat.agent_last_message", "")
      RuntimeMetric.set("heartbeat.agent_last_error", "")
      return { status: "skipped" }
    end

    if agent_heartbeat_skip_when_busy? && Conversation.where(processing: true).exists?
      RuntimeMetric.set("heartbeat.agent_last_run_at", now.iso8601)
      RuntimeMetric.set("heartbeat.agent_last_status", "skipped_busy")
      RuntimeMetric.set("heartbeat.agent_last_provider", "")
      RuntimeMetric.set("heartbeat.agent_last_model", "")
      RuntimeMetric.set("heartbeat.agent_last_message", "")
      RuntimeMetric.set("heartbeat.agent_last_error", "")
      return { status: "skipped" }
    end

    PersonalKnowledgeService.ensure_setup!
    hb_path = File.join(PersonalKnowledgeService.base_dir, "HEARTBEAT.md")
    content = File.exist?(hb_path) ? File.read(hb_path).to_s : ""

    if !agent_heartbeat_force? && heartbeat_content_effectively_empty?(content)
      RuntimeMetric.set("heartbeat.agent_last_run_at", now.iso8601)
      RuntimeMetric.set("heartbeat.agent_last_status", "skipped_empty_file")
      RuntimeMetric.set("heartbeat.agent_last_provider", "")
      RuntimeMetric.set("heartbeat.agent_last_model", "")
      RuntimeMetric.set("heartbeat.agent_last_message", "")
      RuntimeMetric.set("heartbeat.agent_last_error", "")
      return { status: "skipped" }
    end

    snapshot = {
      now: now.iso8601,
      scheduler_last_tick_at: scheduler_tick&.iso8601,
      failed_jobs_last_window: failed_jobs,
      recovered_stuck_conversations: stuck_fixed[:stuck_conversations]
    }

    prompt = <<~PROMPT
      This is a periodic heartbeat check.

      HARD RULES:
      - Do NOT call tools.
      - Do NOT modify any files.
      - If there is nothing important to report, reply with ONLY: HEARTBEAT_OK
      - If something needs attention, reply with a short alert message (no HEARTBEAT_OK).

      System snapshot (trusted):
      #{JSON.pretty_generate(snapshot)}

      HEARTBEAT.md (user-maintained checklist):
      #{content.to_s.strip}
    PROMPT

    candidates = agent_heartbeat_model_candidates
    attempts = []
    selected = nil
    text = nil

    started = Time.current
    candidates.each do |p, m|
      begin
        # Confirm the model works by actually completing a minimal heartbeat prompt.
        text = run_pi_text(prompt, provider: p, model: m)
        selected = [p, m]
        break
      rescue StandardError => e
        attempts << { provider: p.to_s, model: m.to_s, error: "#{e.class}: #{e.message}" }
        next
      end
    end
    duration_ms = ((Time.current - started) * 1000).to_i

    RuntimeMetric.set("heartbeat.agent_last_run_at", now.iso8601)
    RuntimeMetric.set("heartbeat.agent_last_duration_ms", duration_ms.to_s)
    RuntimeMetric.set("heartbeat.agent_last_attempts", attempts.to_json) if attempts.any?

    unless selected
      RuntimeMetric.set("heartbeat.agent_last_status", "failed")
      RuntimeMetric.set("heartbeat.agent_last_provider", "")
      RuntimeMetric.set("heartbeat.agent_last_model", "")
      RuntimeMetric.set("heartbeat.agent_last_message", "")
      RuntimeMetric.set(
        "heartbeat.agent_last_error",
        (attempts.last && attempts.last[:error]).to_s.presence || "All candidate heartbeat models failed"
      )
      return { status: "failed", error: "all_candidate_models_failed" }
    end

    provider, model = selected

    cleaned = strip_heartbeat_token(text, max_ack_chars: agent_heartbeat_ack_max_chars)

    RuntimeMetric.set("heartbeat.agent_last_provider", provider.to_s)
    RuntimeMetric.set("heartbeat.agent_last_model", model.to_s)
    RuntimeMetric.set("heartbeat.agent_last_error", "")

    if cleaned[:should_skip]
      RuntimeMetric.set("heartbeat.agent_last_status", cleaned[:did_strip] ? "ok_token" : "ok_empty")
      RuntimeMetric.set("heartbeat.agent_last_message", "")
      return { status: "ok" }
    end

    msg = cleaned[:text].to_s.strip
    msg = msg[0, 500] + "…" if msg.length > 500

    RuntimeMetric.set("heartbeat.agent_last_status", "alert")
    RuntimeMetric.set("heartbeat.agent_last_message", msg)

    { status: "alert", message: msg }
  rescue StandardError => e
    RuntimeMetric.set("heartbeat.agent_last_run_at", now.iso8601) rescue nil
    RuntimeMetric.set("heartbeat.agent_last_status", "failed") rescue nil
    RuntimeMetric.set("heartbeat.agent_last_error", "#{e.class}: #{e.message}" ) rescue nil
    { status: "failed", error: "#{e.class}: #{e.message}" }
  end

  def agent_heartbeat_model_candidates
    candidates = []

    env_provider = ENV["PI_HEARTBEAT_PROVIDER"].to_s.strip
    env_model = ENV["PI_HEARTBEAT_MODEL"].to_s.strip
    candidates << [env_provider, env_model] if env_provider.present? && env_model.present?

    # Try last known good first (if previous run actually executed an agent heartbeat successfully).
    begin
      last_status = RuntimeMetric.get("heartbeat.agent_last_status").to_s
      last_provider = RuntimeMetric.get("heartbeat.agent_last_provider").to_s
      last_model = RuntimeMetric.get("heartbeat.agent_last_model").to_s

      if last_provider.present? && last_model.present? && last_status.present? &&
          !last_status.start_with?("failed") && !last_status.start_with?("skipped")
        candidates << [last_provider, last_model]
      end
    rescue StandardError
      nil
    end

    # Prefer free / zero-cost models for heartbeat checks (OpenClaw-style).
    candidates.concat([
      ["opencode", "minimax-m2.1-free"],
      ["openrouter", "deepseek/deepseek-r1-0528:free"],
      ["openrouter", "qwen/qwen3-coder:free"]
    ])

    # If pi reports any other :free model, try it too.
    begin
      available = PiModelsService.models
      if available.is_a?(Array)
        free = available.find { |x| x.is_a?(Hash) && x["model"].to_s.include?(":free") }
        candidates << [free["provider"].to_s, free["model"].to_s] if free
      end
    rescue StandardError
      nil
    end

    begin
      defaults = PiModelsService.default_provider_model
      candidates << [defaults[:provider].to_s, defaults[:model].to_s] if defaults.present?
    rescue StandardError
      nil
    end

    candidates << [ENV["PI_PROVIDER"].presence || "opencode", ENV["PI_MODEL"].presence || "minimax-m2.1-free"]

    seen = {}
    candidates.filter_map do |p, m|
      p = p.to_s.strip
      m = m.to_s.strip
      next if p.blank? || m.blank?

      key = "#{p}/#{m}"
      next if seen[key]

      seen[key] = true
      [p, m]
    end
  end

  def resolve_agent_heartbeat_model
    agent_heartbeat_model_candidates.first
  end

  def run_pi_text(prompt, provider:, model:)
    buffer = +""
    final = nil
    last_assistant = nil

    PiRpcPool.with_client(provider: provider, model: model, no_tools: true) do |pi|
      pi.prompt(prompt) do |event|
        case event["type"]
        when "message_update"
          ev = event["assistantMessageEvent"]
          next unless ev.is_a?(Hash)
          next unless ev["type"] == "text_delta"

          delta = ev["delta"].to_s
          buffer << delta if delta.present?

        when "message_end"
          msg = event["message"]
          next unless msg.is_a?(Hash) && msg["role"].to_s == "assistant"

          last_assistant = msg

          if msg["stopReason"].to_s == "error" || msg["errorMessage"].present?
            raise PiRpcService::Error, (msg["errorMessage"].presence || "pi assistant stopReason=error")
          end

          # Non-streaming fallback
          if buffer.to_s.strip.blank? && msg["content"].is_a?(Array)
            extracted = extract_text_from_content(msg["content"])
            buffer = extracted if extracted.present?
          end

        when "agent_end"
          final = buffer

          if event["messages"].is_a?(Array)
            last_assistant ||= event["messages"].reverse.find { |m| m.is_a?(Hash) && m["role"].to_s == "assistant" }
          end

          if last_assistant.is_a?(Hash) && (last_assistant["stopReason"].to_s == "error" || last_assistant["errorMessage"].present?)
            raise PiRpcService::Error, (last_assistant["errorMessage"].presence || "pi assistant stopReason=error")
          end

          if final.to_s.strip.blank? && last_assistant&.dig("content").is_a?(Array)
            extracted = extract_text_from_content(last_assistant["content"])
            final = extracted if extracted.present?
          end
        end
      end
    end

    out = (final.presence || buffer).to_s.strip
    raise PiRpcService::Error, "Empty response from #{provider}/#{model}" if out.blank?

    out
  end

  def extract_text_from_content(content)
    return "" unless content.is_a?(Array)

    content.filter_map do |block|
      next unless block.is_a?(Hash)
      next if block["type"].to_s == "thinking"

      block["type"].to_s == "text" ? block["text"].to_s : nil
    end.join("\n").strip
  end

  def heartbeat_content_effectively_empty?(content)
    return true if content.blank?

    content.to_s.split("\n").each do |line|
      trimmed = line.to_s.strip
      next if trimmed.blank?

      # Markdown headers: '# Heading' / '## Heading'
      next if trimmed.match?(/^#+(\s|$)/)

      # HTML comments
      next if trimmed.start_with?("<!--")

      # Empty markdown list items: '-', '- [ ]', '* [x]', etc.
      next if trimmed.match?(/^[-*+]\s*(\[[\sXx]?\]\s*)?$/)

      # Found content
      return false
    end

    true
  end

  def strip_heartbeat_token(raw, max_ack_chars:)
    token = "HEARTBEAT_OK"
    text = raw.to_s.strip
    return { should_skip: true, text: "", did_strip: false } if text.blank?

    # Normalize lightweight markup so **HEARTBEAT_OK** or <b>HEARTBEAT_OK</b> still strips.
    normalized = text
      .gsub(/<[^>]*>/, " ")
      .gsub(/&nbsp;/i, " ")
      .gsub(/^[*`~_]+/, "")
      .gsub(/[*`~_]+$/, "")
      .strip

    stripped, did_strip = strip_token_at_edges(normalized, token)

    if did_strip
      rest = stripped.strip
      return { should_skip: true, text: "", did_strip: true } if rest.blank?
      return { should_skip: true, text: "", did_strip: true } if rest.length <= max_ack_chars.to_i
      return { should_skip: false, text: rest, did_strip: true }
    end

    { should_skip: false, text: text, did_strip: false }
  end

  def strip_token_at_edges(text, token)
    t = text.to_s.strip
    did = false

    loop do
      changed = false
      if t.start_with?(token)
        t = t[token.length..].to_s.strip
        did = true
        changed = true
      end
      if t.end_with?(token)
        t = t[0, [0, t.length - token.length].max].to_s.strip
        did = true
        changed = true
      end
      break unless changed
    end

    [t.gsub(/\s+/, " ").strip, did]
  end

  def record_heartbeat_event!(started_at:, duration_ms:, status:, alerts:, fixed:, agent_res:)
    HeartbeatEvent.create!(
      started_at: started_at,
      duration_ms: duration_ms,
      status: status.to_s,
      alerts_json: alerts.to_json,
      agent_status: agent_res[:status].to_s,
      agent_provider: RuntimeMetric.get("heartbeat.agent_last_provider").to_s,
      agent_model: RuntimeMetric.get("heartbeat.agent_last_model").to_s,
      agent_message: RuntimeMetric.get("heartbeat.agent_last_message").to_s,
      agent_error: RuntimeMetric.get("heartbeat.agent_last_error").to_s,
      stuck_conversations_fixed: fixed[:stuck_conversations].to_i,
      stuck_messages_fixed: fixed[:stuck_messages].to_i,
      stuck_tool_calls_fixed: fixed[:stuck_tool_calls].to_i
    )

    keep = ENV.fetch("HEARTBEAT_HISTORY_KEEP", "500").to_i
    HeartbeatEvent.order(started_at: :desc).offset(keep).delete_all if keep.positive?
  rescue ActiveRecord::StatementInvalid
    # migrations not applied in some environments
    nil
  rescue StandardError => e
    Rails.logger.debug("SystemHeartbeatJob: failed to record heartbeat event: #{e.class}: #{e.message}") if defined?(Rails)
  end

  def send_push_alerts!(status:, alerts:)
    body = alerts.join("\n").to_s
    body = body[0, 500] + "…" if body.length > 500

    project_ids = PushSubscription.where.not(project_id: nil).distinct.pluck(:project_id)
    project_ids.each do |pid|
      PushNotificationService.notify_project(
        project_id: pid,
        title: "Gotar Bot heartbeat: #{status}",
        body: body.presence || "No details",
        url: Rails.application.routes.url_helpers.monitoring_path
      )
    end
  rescue StandardError => e
    Rails.logger.error("SystemHeartbeatJob: push notify failed: #{e.class}: #{e.message}")
  end
end

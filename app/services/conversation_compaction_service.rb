# frozen_string_literal: true

# ConversationCompactionService
#
# When chat history gets too long to include verbatim in the prompt, we compact
# older messages into a short summary using an LLM.
#
# Strategy:
# - Keep a rolling `conversations.compacted_summary`
# - Track how far it covers with `compacted_until_message_id`
# - Keep the last N messages as "recent" verbatim context
#
# This is intentionally conservative: if compaction fails, we fall back to simple
# truncation.
class ConversationCompactionService
  class << self
    ENABLED = ENV.fetch("PI_CHAT_COMPACTION_ENABLED", "true") == "true"

    SUMMARY_MAX_CHARS = ENV.fetch("PI_CHAT_SUMMARY_MAX_CHARS", "2000").to_i
    KEEP_RECENT_MESSAGES = ENV.fetch("PI_CHAT_COMPACT_KEEP_RECENT_MESSAGES", "8").to_i
    TRANSCRIPT_PER_MESSAGE_MAX_CHARS = ENV.fetch("PI_CHAT_COMPACT_TRANSCRIPT_PER_MESSAGE_MAX_CHARS", "1200").to_i
    TRANSCRIPT_MAX_CHARS = ENV.fetch("PI_CHAT_COMPACT_TRANSCRIPT_MAX_CHARS", "20000").to_i

    # We trigger compaction when the raw history would exceed the prompt history budget.
    def context_for_prompt(conversation:, before_time:, history_max_messages:, history_max_chars:, history_per_message_max_chars:)
      return "" unless conversation

      # If the migration hasn't been applied yet, fall back to simple truncation.
      unless conversation.respond_to?(:compacted_summary) && conversation.respond_to?(:compacted_until_message_id)
        msgs = conversation.messages
          .where(role: %w[user assistant])
          .where("created_at < ?", before_time)
          .order(:created_at)

        return format_messages_for_history(
          msgs,
          max_messages: history_max_messages,
          max_chars: history_max_chars,
          per_message_max_chars: history_per_message_max_chars
        )
      end

      msgs = conversation.messages
        .where(role: %w[user assistant])
        .where("created_at < ?", before_time)
        .order(:created_at)

      verbatim, truncated = format_messages_for_history(
        msgs,
        max_messages: history_max_messages,
        max_chars: history_max_chars,
        per_message_max_chars: history_per_message_max_chars,
        return_truncated: true
      )

      # Fast-path: small enough, include verbatim.
      return verbatim if !ENABLED || !truncated

      # Try to ensure we have an up-to-date rolling summary.
      ensure_compacted!(conversation: conversation, msgs: msgs)

      # Build remaining verbatim messages after the compacted cut.
      cut_id = conversation.compacted_until_message_id.to_i
      remaining = msgs.where("id > ?", cut_id)

      remaining_text = format_messages_for_history(
        remaining,
        max_messages: [history_max_messages, KEEP_RECENT_MESSAGES].max,
        max_chars: [history_max_chars - (conversation.compacted_summary.to_s.length + 200), 1000].max,
        per_message_max_chars: history_per_message_max_chars
      )

      parts = []
      if conversation.compacted_summary.present?
        summary = conversation.compacted_summary.to_s.strip
        summary = summary[0, SUMMARY_MAX_CHARS].rstrip + "…" if summary.length > SUMMARY_MAX_CHARS
        parts << "Conversation summary (compacted):\n#{summary}"
      end

      parts << "Recent messages:\n#{remaining_text}" if remaining_text.present?

      parts.join("\n\n")
    rescue StandardError => e
      Rails.logger.debug("ConversationCompactionService: fallback due to #{e.class}: #{e.message}") if defined?(Rails)
      # Fallback: naive truncation.
      format_messages_for_history(
        msgs,
        max_messages: history_max_messages,
        max_chars: history_max_chars,
        per_message_max_chars: history_per_message_max_chars
      )
    end

    private

    def ensure_compacted!(conversation:, msgs:)
      # Determine which messages are not yet compacted.
      cut_id = conversation.compacted_until_message_id.to_i
      pending = msgs.where("id > ?", cut_id)

      # Nothing to compact.
      return if pending.count <= KEEP_RECENT_MESSAGES

      # If pending is already small enough, don't compact.
      pending_chars = pending.sum { |m| m.content.to_s.length }
      return if pending.count <= (KEEP_RECENT_MESSAGES + 4) && pending_chars <= 6_000

      # Compact a bounded chunk (so we don't blow the compaction model context window).
      pending_arr = pending.to_a

      # We must leave at least KEEP_RECENT_MESSAGES un-compacted.
      max_compactable = [0, pending_arr.length - KEEP_RECENT_MESSAGES].max
      return if max_compactable <= 0

      chunk = []
      chars = 0

      pending_arr.first(max_compactable).each do |m|
        role = m.role == "user" ? "User" : "Assistant"
        txt = m.content.to_s.strip
        txt = txt[0, TRANSCRIPT_PER_MESSAGE_MAX_CHARS].rstrip + "…" if txt.length > TRANSCRIPT_PER_MESSAGE_MAX_CHARS
        block = "#{role}: #{txt}"

        projected = chars + block.length + 2
        break if projected > TRANSCRIPT_MAX_CHARS

        chunk << m
        chars = projected
      end

      return if chunk.empty?

      new_cut_id = chunk.last.id
      transcript = format_messages_for_transcript(chunk)

      prev_summary = conversation.compacted_summary.to_s.strip

      prompt = build_compaction_prompt(prev_summary: prev_summary, transcript: transcript)

      provider_model_candidates.each do |provider, model|
        begin
          text = run_pi_text(prompt, provider: provider, model: model)
          next_summary = normalize_summary(text)
          next if next_summary.blank?

          conversation.with_lock do
            # Another job may have compacted further in the meantime.
            current_cut = conversation.compacted_until_message_id.to_i
            next if current_cut >= new_cut_id

            conversation.update!(
              compacted_summary: next_summary,
              compacted_until_message_id: new_cut_id,
              compacted_at: Time.current
            )
          end

          break
        rescue StandardError => e
          Rails.logger.debug("ConversationCompactionService: compaction failed on #{provider}/#{model}: #{e.class}: #{e.message}") if defined?(Rails)
          next
        end
      end
    rescue StandardError
      # best-effort
      nil
    end

    def build_compaction_prompt(prev_summary:, transcript:)
      <<~PROMPT
        You are compacting chat history for a coding assistant.

        HARD RULES:
        - Do NOT call tools.
        - Do NOT modify any files.
        - Do NOT invent facts.
        - Keep the summary concise and practical.
        - Focus on: user intent, decisions made, constraints, open questions, next steps, and stable preferences.

        Output ONLY the updated summary in Markdown.
        Target length: <= #{SUMMARY_MAX_CHARS} characters.

        Existing summary (may be empty):
        #{prev_summary.presence || "(none)"}

        New transcript chunk to fold in:
        #{transcript}

        Now output the updated summary.
      PROMPT
    end

    def normalize_summary(text)
      s = text.to_s.strip
      s = s.gsub(/\A```[a-zA-Z0-9_-]*\s*/m, "").gsub(/```\s*\z/m, "")
      s = s.strip
      s = s[0, SUMMARY_MAX_CHARS].rstrip + "…" if s.length > SUMMARY_MAX_CHARS
      s
    end

    def provider_model_candidates
      # explicit override
      provider = ENV["PI_COMPACT_PROVIDER"].to_s.strip
      model = ENV["PI_COMPACT_MODEL"].to_s.strip
      candidates = []
      candidates << [provider, model] if provider.present? && model.present?

      # Prefer free/cheap models (similar to heartbeat)
      candidates.concat([
        ["opencode", "minimax-m2.1-free"],
        ["openrouter", "deepseek/deepseek-r1-0528:free"],
        ["openrouter", "qwen/qwen3-coder:free"]
      ])

      begin
        avail = PiModelsService.models
        if avail.is_a?(Array)
          free = avail.find { |x| x.is_a?(Hash) && x["model"].to_s.include?(":free") }
          candidates << [free["provider"].to_s, free["model"].to_s] if free
        end
      rescue StandardError
        nil
      end

      # Fallback to pi defaults
      begin
        defaults = PiModelsService.default_provider_model
        candidates << [defaults[:provider].to_s, defaults[:model].to_s]
      rescue StandardError
        nil
      end

      seen = {}
      candidates.filter_map do |p, m|
        p = p.to_s.strip
        m = m.to_s.strip
        next if p.blank? || m.blank?

        k = "#{p}/#{m}"
        next if seen[k]

        seen[k] = true
        [p, m]
      end
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

          when "agent_end"
            final = buffer
            if event["messages"].is_a?(Array)
              last_assistant ||= event["messages"].reverse.find { |m| m.is_a?(Hash) && m["role"].to_s == "assistant" }
            end
            if last_assistant.is_a?(Hash) && (last_assistant["stopReason"].to_s == "error" || last_assistant["errorMessage"].present?)
              raise PiRpcService::Error, (last_assistant["errorMessage"].presence || "pi assistant stopReason=error")
            end
          end
        end
      end

      out = (final.presence || buffer).to_s.strip
      raise PiRpcService::Error, "Empty compaction response" if out.blank?

      out
    end

    def format_messages_for_transcript(messages)
      messages.map do |m|
        role = m.role == "user" ? "User" : "Assistant"
        txt = m.content.to_s.strip
        txt = txt[0, TRANSCRIPT_PER_MESSAGE_MAX_CHARS].rstrip + "…" if txt.length > TRANSCRIPT_PER_MESSAGE_MAX_CHARS
        "#{role}: #{txt}"
      end.join("\n\n")
    end

    def format_messages_for_history(messages_relation, max_messages:, max_chars:, per_message_max_chars:, return_truncated: false)
      blocks = []
      chars = 0
      count = 0
      truncated = false

      messages_relation.to_a.reverse_each do |m|
        break if count >= max_messages

        txt = m.content.to_s.strip
        next if m.role == "assistant" && txt.blank?

        txt = txt[0, per_message_max_chars].rstrip + "…" if txt.length > per_message_max_chars

        role = (m.role == "user") ? "User" : "Assistant"
        block = "#{role}: #{txt}"

        projected = chars + block.length + 2
        if projected > max_chars
          truncated = true
          break
        end

        blocks << block
        chars = projected
        count += 1
      end

      out = blocks.reverse.join("\n\n")
      out = "…\n\n" + out if truncated && out.present?

      return [out, truncated] if return_truncated

      out
    end
  end
end

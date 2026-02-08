# frozen_string_literal: true

require "open3"
require "json"
require "timeout"

class QmdCliService
  class Error < StandardError; end

  DEFAULT_COLLECTION = ENV.fetch("PI_KNOWLEDGE_QMD_COLLECTION", "pi-knowledge")

  def self.qmd_bin
    ENV.fetch("QMD_BIN", "qmd")
  end

  def self.ensure_pi_knowledge_collection!
    PersonalKnowledgeService.ensure_setup!
    ensure_collection!(name: DEFAULT_COLLECTION, path: PersonalKnowledgeService.base_dir, mask: "**/*.md")
  end

  def self.ensure_collection!(name:, path:, mask: "**/*.md")
    list = run!("collection", "list")
    return true if list.include?("\n#{name} ") || list.start_with?("#{name} ") || list.include?("\n#{name}(") || list.include?("\n#{name}\n")

    run!("collection", "add", path.to_s, "--name", name.to_s, "--mask", mask.to_s)
    true
  end

  def self.update!
    ensure_pi_knowledge_collection!
    run!("update", timeout: ENV.fetch("QMD_UPDATE_TIMEOUT_SECONDS", "120").to_i)
  end

  def self.update_and_embed_if_needed!
    out = update!
    embed_if_needed!
    out
  end

  def self.embed_if_needed!
    return false if ENV.fetch("QMD_AUTO_EMBED", "true") != "true"

    st = status
    if embed_needed?(st)
      embed!
      return true
    end

    false
  end

  def self.embed_needed?(status_text)
    t = status_text.to_s
    return true if t.match?(/need embedding/i)
    return true if t.match?(/need embeddings/i)
    return true if t.match?(/need vectors/i)
    return true if t.match?(/pending:\s*\d+\s*need/i)

    false
  end

  def self.embed!(force: false)
    ensure_pi_knowledge_collection!
    args = ["embed"]
    args << "-f" if force
    run!(*args, timeout: ENV.fetch("QMD_EMBED_TIMEOUT_SECONDS", "3600").to_i)
  end

  def self.status
    run!("status")
  end

  # mode: :query (hybrid), :search (bm25), :vsearch (vector)
  def self.search(query, mode: :query, limit: 10, collection: DEFAULT_COLLECTION)
    cmd = case mode.to_sym
          when :search then "search"
          when :vsearch then "vsearch"
          else "query"
          end

    # Prefer MCP for interactive web search (keeps models warm, avoids process startup cost).
    if ENV.fetch("QMD_USE_MCP", "true") == "true"
      begin
        ensure_pi_knowledge_collection!
        res = QmdMcpService.call_tool(cmd, { query: query.to_s, limit: limit.to_i, collection: collection.to_s })
        structured = res["structuredContent"] || res[:structuredContent]
        results = structured && (structured["results"] || structured[:results])
        return results if results.is_a?(Array)

        return []
      rescue StandardError => e
        Rails.logger.debug("QMD MCP failed, falling back to CLI: #{e.message}") if defined?(Rails)
      end
    end

    ensure_pi_knowledge_collection!

    timeout = case mode.to_sym
              when :query then ENV.fetch("QMD_QUERY_TIMEOUT_SECONDS", "90").to_i
              when :vsearch then ENV.fetch("QMD_VSEARCH_TIMEOUT_SECONDS", "45").to_i
              else ENV.fetch("QMD_TIMEOUT_SECONDS", "20").to_i
              end

    json = run!(cmd, query.to_s, "--json", "-n", limit.to_i.to_s, "-c", collection.to_s, timeout: timeout)
    JSON.parse(json)
  rescue JSON::ParserError
    []
  end

  def self.run!(*args, timeout: ENV.fetch("QMD_TIMEOUT_SECONDS", "20").to_i)
    stdout_str = +""
    stderr_str = +""
    status = nil

    # Use a process group so we can kill child processes (node-llama-cpp) on timeout.
    Open3.popen3(qmd_bin, *args.map(&:to_s), pgroup: true) do |stdin, stdout, stderr, wait_thr|
      stdin.close

      out_t = Thread.new do
        begin
          stdout_str << stdout.read
        rescue IOError
          # stream may be closed on timeout/termination
        end
      end

      err_t = Thread.new do
        begin
          stderr_str << stderr.read
        rescue IOError
          # stream may be closed on timeout/termination
        end
      end

      begin
        Timeout.timeout(timeout) do
          out_t.join
          err_t.join
          status = wait_thr.value
        end
      rescue Timeout::Error
        pid = wait_thr.pid
        begin
          Process.kill("-TERM", pid)
        rescue StandardError
          nil
        end
        sleep 0.2
        begin
          Process.kill("-KILL", pid)
        rescue StandardError
          nil
        end

        # Ensure reader threads don't keep reporting exceptions.
        out_t.kill
        err_t.kill

        raise Error, "qmd #{args.join(' ')} timed out after #{timeout}s"
      end
    end

    return stdout_str if status&.success?

    raise Error, "qmd #{args.join(' ')} failed: #{stderr_str.presence || stdout_str.presence || status.to_s}"
  end
end

# frozen_string_literal: true

require "open3"
require "json"
require "securerandom"
require "timeout"

# QmdMcpService
#
# Runs `qmd mcp` as a long-lived subprocess and calls MCP tools over stdio.
# The MCP stdio framing is newline-delimited JSON-RPC messages.
#
# This keeps the underlying node-llama-cpp models warm (QMD itself manages
# model/context lifecycles internally), avoiding the cost of process startup
# and repeated model loads for each request.
class QmdMcpService
  class Error < StandardError; end

  PROTOCOL_VERSION = ENV.fetch("MCP_PROTOCOL_VERSION", "2025-06-18")

  class << self
    def call_tool(name, arguments = {}, timeout: nil)
      ensure_started!

      id = next_id
      msg = {
        jsonrpc: "2.0",
        id: id,
        method: "tools/call",
        params: {
          name: name.to_s,
          arguments: arguments || {}
        }
      }

      waiter = WaitingRequest.new

      mutex.synchronize do
        pending[id] = waiter
        write_message!(msg)
      end

      waiter.wait(timeout: timeout || default_timeout_for_tool(name))
    ensure
      mutex.synchronize { pending.delete(id) } if id
    end

    def healthy?
      @started && @wait_thr&.alive?
    end

    def stop!
      mutex.synchronize do
        return unless @started

        @started = false

        begin
          @stdin&.close
        rescue StandardError
          nil
        end

        begin
          # Kill process group to ensure node-llama-cpp children exit.
          pid = @wait_thr&.pid
          Process.kill("-TERM", -pid) if pid && pid.positive?
        rescue StandardError
          nil
        end

        begin
          pid = @wait_thr&.pid
          Process.kill("-KILL", -pid) if pid && pid.positive?
        rescue StandardError
          nil
        end

        @reader_thread&.kill
        @stderr_thread&.kill

        @stdin = @stdout = @stderr = @wait_thr = @reader_thread = @stderr_thread = nil
      end
    end

    private

    def ensure_started!
      return if healthy? && @initialized

      # Ensure the knowledge base exists and QMD collection is configured.
      # (Uses CLI, but only once at process start.)
      begin
        QmdCliService.ensure_pi_knowledge_collection!
      rescue StandardError => e
        raise Error, "QMD MCP startup failed (ensure collection): #{e.message}"
      end

      already_started = false

      mutex.synchronize do
        already_started = healthy?
        spawn_mcp_process! unless already_started
      end

      # IMPORTANT: initialize outside the mutex to avoid deadlocking the reader thread.
      unless @initialized
        mcp_initialize!
        @initialized = true
      end
    end

    def spawn_mcp_process!
      qmd_bin = QmdCliService.qmd_bin

      @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(qmd_bin, "mcp", pgroup: true)
      @stdin.sync = true

      @started = true
      @initialized = false

      @reader_thread = Thread.new { reader_loop }
      @stderr_thread = Thread.new { drain_stderr }

      at_exit { stop! }
    end

    def mcp_initialize!
      id = next_id
      waiter = WaitingRequest.new
      mutex.synchronize { pending[id] = waiter }

      write_message!({
        jsonrpc: "2.0",
        id: id,
        method: "initialize",
        params: {
          protocolVersion: PROTOCOL_VERSION,
          capabilities: {},
          clientInfo: {
            name: "gotar-bot",
            version: "1.0"
          }
        }
      })

      waiter.wait(timeout: ENV.fetch("QMD_MCP_INIT_TIMEOUT_SECONDS", "60").to_i)

      # Notify initialized (no response expected)
      write_message!({
        jsonrpc: "2.0",
        method: "notifications/initialized"
      })
    ensure
      pending.delete(id)
    end

    def reader_loop
      while (line = @stdout.gets)
        begin
          line = line.to_s.strip
          next if line.blank?

          msg = JSON.parse(line)

          # Response
          if msg.key?("id")
            id = msg["id"]
            waiter = mutex.synchronize { pending[id] }
            waiter&.fulfill(msg)
            next
          end

          # Notifications: ignore (could be progress/logging)
        rescue JSON::ParserError
          # ignore garbage
        rescue StandardError => e
          Rails.logger.debug("QMD MCP reader error: #{e.class}: #{e.message}") if defined?(Rails)
        end
      end
    rescue StandardError => e
      Rails.logger.debug("QMD MCP reader loop ended: #{e.class}: #{e.message}") if defined?(Rails)
    ensure
      # mark unhealthy
      @started = false
    end

    def drain_stderr
      # QMD prints progress/model logs (and sometimes control sequences) to stderr.
      # Drain it as raw bytes so the pipe never fills up and blocks the subprocess.
      loop do
        chunk = @stderr.readpartial(4096)
        next if chunk.nil? || chunk.empty?

        if defined?(Rails) && ENV.fetch("QMD_MCP_LOG", "false") == "true"
          Rails.logger.debug("QMD MCP stderr: #{chunk.to_s.encode("UTF-8", invalid: :replace, undef: :replace).strip}")
        end
      end
    rescue EOFError, IOError
      nil
    rescue StandardError
      nil
    end

    def write_message!(hash)
      @stdin.puts(JSON.dump(hash))
    rescue StandardError => e
      raise Error, "Failed to write to qmd mcp: #{e.message}"
    end

    def pending
      @pending ||= {}
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def next_id
      @seq ||= 0
      @seq += 1
    end

    def default_timeout_for_tool(name)
      case name.to_s
      when "query" then ENV.fetch("QMD_QUERY_TIMEOUT_SECONDS", "90").to_i
      when "vsearch" then 45
      else 10
      end
    end
  end

  class WaitingRequest
    def initialize
      @mutex = Mutex.new
      @cv = ConditionVariable.new
      @done = false
      @msg = nil
    end

    def fulfill(msg)
      @mutex.synchronize do
        @done = true
        @msg = msg
        @cv.broadcast
      end
    end

    def wait(timeout:)
      @mutex.synchronize do
        unless @done
          @cv.wait(@mutex, timeout)
        end

        raise QmdMcpService::Error, "QMD MCP request timed out after #{timeout}s" unless @done

        # JSON-RPC error
        if @msg.is_a?(Hash) && @msg["error"]
          raise QmdMcpService::Error, @msg["error"].to_s
        end

        result = @msg["result"]
        return result if result

        raise QmdMcpService::Error, "Invalid QMD MCP response"
      end
    end
  end
end

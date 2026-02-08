# frozen_string_literal: true

require "json"
require "open3"
require "timeout"

# Service for communicating with pi coding agent via RPC mode
# Pi RPC uses JSON protocol over stdin/stdout
class PiRpcService
  class Error < StandardError; end
  class TimeoutError < Error; end
  class ProcessError < Error; end

  RPC_TIMEOUT = Rails.configuration.pi_rpc[:rpc_timeout] # seconds
  STARTUP_TIMEOUT = Rails.configuration.pi_rpc[:startup_timeout] # seconds
  MAX_RETRY_ATTEMPTS = Rails.configuration.pi_rpc[:max_retry_attempts]

  attr_reader :pid

  def initialize(provider: nil, model: nil, tools: nil, no_tools: false)
    @provider = provider
    @model = model
    @tools = tools
    @no_tools = no_tools

    @stdin = nil
    @stdout = nil
    @stderr = nil
    @wait_thread = nil
    @mutex = Mutex.new
  end

  # Start the pi RPC subprocess
  def start
    @mutex.synchronize do
      return if @stdin # Already started

      Rails.logger.info "Starting pi RPC subprocess..."
      @stderr_buffer = +""

      provider = @provider.presence || ENV["PI_PROVIDER"].presence
      model = @model.presence || ENV["PI_MODEL"].presence

      # Start pi in RPC mode.
      # If provider/model are not explicitly provided, we let pi use its own settings.json defaults.
      cmd = ["pi"]
      cmd += ["--provider", provider] if provider.present?
      cmd += ["--model", model] if model.present?

      if @no_tools
        cmd << "--no-tools"
      elsif @tools.present?
        cmd += ["--tools", @tools.to_s]
      end

      cmd += ["--mode", "rpc", "--no-session"]

      @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(*cmd)

      # Drain stderr so the subprocess can't block if it becomes chatty.
      @stderr_thread = Thread.new do
        begin
          loop do
            chunk = @stderr.readpartial(4096)
            break if chunk.nil? || chunk.empty?
            @stderr_buffer << chunk
            # keep last ~32KB
            @stderr_buffer = @stderr_buffer.byteslice(-32_768, 32_768) if @stderr_buffer.bytesize > 32_768
          end
        rescue EOFError, IOError
          nil
        rescue StandardError
          nil
        end
      end

      @pid = @wait_thread.pid
      Rails.logger.info "Pi RPC started with PID #{@pid}"

      # Give it a moment to initialize
      sleep(0.5)
    end
  end

  # Stop the pi RPC subprocess
  def stop
    @mutex.synchronize do
      return unless @stdin

      Rails.logger.info "Stopping pi RPC subprocess (PID #{@pid})..."

      @stdin&.close
      @stdout&.close
      @stderr&.close

      if @wait_thread&.alive?
        Process.kill("TERM", @pid) rescue nil
        Timeout.timeout(5) { @wait_thread.join }
      end

      @stderr_thread&.kill rescue nil
      @stderr_thread = nil

      @stdin = @stdout = @stderr = @wait_thread = nil
      @pid = nil
    end
  end

  # Check if the RPC process is running
  def running?
    @wait_thread&.alive? || false
  end

  # Send a prompt and stream responses
  # Yields events as they arrive
  #
  # Supports optional images per pi RPC spec:
  # images: [{type: "image", data: "<base64>", mimeType: "image/png"}, ...]
  def prompt(message, images: nil, &block)
    start unless running?

    payload = {
      type: "prompt",
      message: message
    }
    payload[:images] = images if images.present?

    send_command(payload)

    # Read events until we get a complete response
    read_response_stream(&block)
  end

  # Get current session state
  def get_state
    send_command({ type: "get_state" })
    read_response
  end

  # Get all messages in the conversation
  def get_messages
    send_command({ type: "get_messages" })
    read_response
  end

  # Abort current operation
  def abort
    send_command({ type: "abort" })
    read_response
  end

  # Start a new session
  def new_session
    send_command({ type: "new_session" })
    read_response
  end

  # Set the model
  def set_model(provider:, model_id:)
    send_command({
      type: "set_model",
      provider: provider,
      modelId: model_id
    })
    read_response
  end

  # Get available models
  def get_available_models
    send_command({ type: "get_available_models" })
    read_response
  end

  private

  # Send a JSON command to pi
  def send_command(command)
    @mutex.synchronize do
      raise ProcessError, "RPC process not running" unless running?

      json = command.to_json
      Rails.logger.debug "Sending to pi: #{json}"
      @stdin.puts(json)
      @stdin.flush
    end
  end

  # Read a single response (blocking)
  def read_response
    Timeout.timeout(RPC_TIMEOUT) do
      loop do
        line = @stdout.gets
        return nil unless line

        # Clean noisy terminal output and try to extract JSON.
        line = line.gsub(/\x07/, "")
        json_start = line.index("{")
        next unless json_start

        candidate = line[json_start..].to_s.strip
        next if candidate.empty?

        Rails.logger.debug "Received from pi: #{candidate}"

        begin
          parsed = JSON.parse(candidate)
        rescue JSON::ParserError
          cleaned = candidate.gsub(/\x1b\]777;[^,]*,/, "")
                             .gsub(/\e\]777;[^,]*,/, "")
                             .gsub(/\x1b\[[0-9;]*[mGKF]/, "")
                             .gsub(/\e\[[0-9;]*[mGKF]/, "")
                             .strip
          begin
            parsed = JSON.parse(cleaned)
          rescue JSON::ParserError
            Rails.logger.debug "Pi RPC: skipping non-JSON output"
            next
          end
        end

        # For non-stream RPC commands we only want the command response.
        next unless parsed.is_a?(Hash) && parsed["type"].to_s == "response"

        return parsed
      end
    end
  rescue Timeout::Error
    raise TimeoutError, "RPC response timeout"
  end

  # Read response stream, yielding events
  def read_response_stream
    events_count = 0
    start_time = Time.now
    events_queue = Queue.new
    agent_end_seen = false

    # Thread to read from stdout
    reader_thread = Thread.new do
      begin
        loop do
          line = @stdout.gets
          break unless line

          # Clean the line - remove BEL and find JSON
          line = line.gsub(/\x07/, '')
          json_start = line.index('{')
          if json_start
            line = line[json_start..-1]
          else
            next
          end

          begin
            event = JSON.parse(line)
            # no-op: reader thread pushes events to queue
            events_queue << event
          rescue JSON::ParserError
            # Try more cleaning
            cleaned = line.gsub(/\x1b\]777;[^,]*,/, '')
                          .gsub(/\e\]777;[^,]*,/, '')
                          .gsub(/\x1b\[[0-9;]*[mGKF]/, '')
                          .gsub(/\e\[[0-9;]*[mGKF]/, '')
                          .strip
            begin
              event = JSON.parse(cleaned)
              # no-op: reader thread pushes cleaned events to queue
              events_queue << event
            rescue JSON::ParserError
              Rails.logger.debug "Pi RPC: skipping non-JSON output"
            end
          end
        end
      rescue => e
        Rails.logger.error "Reader thread error: #{e.message}"
      end
    end

    Timeout.timeout(RPC_TIMEOUT) do
      loop do
        # If the reader thread ended before we saw agent_end, treat as a hard failure.
        unless reader_thread.alive?
          # Give the queue a brief chance to drain.
          sleep 0.05
          if events_queue.empty? && !agent_end_seen
            raise ProcessError, "Pi RPC stream ended unexpectedly (no agent_end). #{stderr_tail_for_error}"
          end
        end

        # Wait for events (without blocking forever)
        if events_queue.empty?
          sleep 0.02
          next
        end
        event = events_queue.pop(true) rescue nil
        next unless event

        elapsed = Time.now - start_time
        if elapsed > RPC_TIMEOUT
          raise TimeoutError, "RPC response timeout after #{RPC_TIMEOUT} seconds"
        end

        events_count += 1
        Rails.logger.debug "PI Event #{events_count}: #{event['type']}"

        yield event if block_given?

        # Check for completion
        if event["type"] == "agent_end"
          agent_end_seen = true
          Rails.logger.info "Pi RPC: agent_end after #{elapsed.round(1)}s"
          break
        end
      end
    end

    # If we exited without agent_end, that's also a failure.
    raise ProcessError, "Pi RPC finished without agent_end. #{stderr_tail_for_error}" unless agent_end_seen

    # Clean up reader thread
    reader_thread.kill rescue nil
    reader_thread.join(1) rescue nil
  rescue Timeout::Error
    reader_thread.kill rescue nil
    raise TimeoutError, "RPC response timeout after #{RPC_TIMEOUT} seconds"
  end

  def stderr_tail_for_error
    buf = (@stderr_buffer || "").to_s
    return "" if buf.blank?

    tail = buf.split(/\r?\n/).last(20).join(" | ")
    "(stderr: #{tail})"
  end
end

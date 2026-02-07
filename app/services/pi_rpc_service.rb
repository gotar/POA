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

  def initialize(provider: nil, model: nil)
    @provider = provider
    @model = model

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

      provider = @provider.presence || ENV.fetch("PI_PROVIDER", "opencode")
      model = @model.presence || ENV.fetch("PI_MODEL", "minimax-m2.1-free")

      # Start pi in RPC mode (explicit provider/model to avoid picking up wrong defaults)
      @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(
        "pi", "--provider", provider, "--model", model, "--mode", "rpc", "--no-session"
      )

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
  def prompt(message, &block)
    start unless running?

    send_command({
      type: "prompt",
      message: message
    })

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
      line = @stdout.gets
      return nil unless line

      line = line.strip
      return nil if line.empty?

      Rails.logger.debug "Received from pi: #{line}"
      JSON.parse(line)
    end
  rescue Timeout::Error
    raise TimeoutError, "RPC response timeout"
  end

  # Read response stream, yielding events
  def read_response_stream
    events_count = 0
    start_time = Time.now
    events_queue = Queue.new

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
        # Check if reader thread is still alive
        unless reader_thread.alive?
          Rails.logger.debug "Pi RPC: reader thread ended"
          break
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
          Rails.logger.info "Pi RPC: agent_end after #{elapsed.round(1)}s"
          break
        end
      end
    end

    # Clean up reader thread
    reader_thread.kill rescue nil
    reader_thread.join(1) rescue nil
  rescue Timeout::Error
    reader_thread.kill rescue nil
    raise TimeoutError, "RPC response timeout after #{RPC_TIMEOUT} seconds"
  end
end

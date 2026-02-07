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

  def initialize
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

      # Start pi in RPC mode
      @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(
        "pi --mode rpc --no-session"
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
    Timeout.timeout(RPC_TIMEOUT) do
      loop do
        line = @stdout.gets
        break unless line

        line = line.strip
        next if line.empty?

        # Skip non-JSON lines (like blob data)
        begin
          event = JSON.parse(line)
        rescue JSON::ParserError => e
          Rails.logger.warn "Skipping non-JSON line from PI: #{line[0..100]}..."
          next
        end

        Rails.logger.debug "Received event: #{event['type']}"

        yield event if block_given?

        # Break only on agent_end event (final completion)
        if event["type"] == "agent_end"
          break
        end
      end
    end
  rescue Timeout::Error
    raise TimeoutError, "RPC response timeout"
  end
end

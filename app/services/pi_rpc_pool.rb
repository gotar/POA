# frozen_string_literal: true

# PiRpcPool
#
# Keeps pi RPC subprocesses warm across background job runs to reduce startup
# overhead on resource-constrained machines.
#
# Pool is keyed by provider/model. Each entry is guarded by a mutex to ensure
# a single in-flight RPC stream per process.

require "timeout"

class PiRpcPool
  class << self
    def with_client(provider: nil, model: nil, tools: nil, no_tools: false)
      key = pool_key(provider, model, tools: tools, no_tools: no_tools)
      entry = nil

      mutex.synchronize do
        entry = pool[key] ||= Entry.new(provider: provider, model: model, tools: tools, no_tools: no_tools)
      end

      entry.with_client { |pi| yield pi }
    end

    def stop_idle!(idle_seconds: ENV.fetch("PI_RPC_POOL_IDLE_SECONDS", "600").to_i)
      cutoff = Time.current - idle_seconds.to_i.seconds

      mutex.synchronize do
        pool.delete_if do |_key, entry|
          next false unless entry.last_used_at
          next false unless entry.last_used_at < cutoff

          entry.stop!
          true
        end
      end
    rescue StandardError
      nil
    end

    def stop_all!
      mutex.synchronize do
        pool.values.each(&:stop!)
        pool.clear
      end
    rescue StandardError
      nil
    end

    private

    def pool
      @pool ||= {}
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def pool_key(provider, model, tools:, no_tools:)
      p = provider.to_s.strip
      m = model.to_s.strip
      p = "default" if p.blank?
      m = "default" if m.blank?

      t = if no_tools
        "no-tools"
      elsif tools.to_s.strip.present?
        "tools:#{tools.to_s.strip}"
      else
        "tools:default"
      end

      "#{p}/#{m}/#{t}"
    end
  end

  class Entry
    attr_reader :last_used_at

    def initialize(provider:, model:, tools:, no_tools:)
      @provider = provider
      @model = model
      @tools = tools
      @no_tools = no_tools
      @mutex = Mutex.new
      @pi = PiRpcService.new(provider: provider, model: model, tools: tools, no_tools: no_tools)
      @last_used_at = nil
    end

    def with_client
      @mutex.synchronize do
        @pi.start unless @pi.running?

        # Ensure we don't leak state between independent prompts.
        # IMPORTANT: keep this short; if pi gets wedged, restart it.
        begin
          reset_timeout = ENV.fetch("PI_RPC_POOL_RESET_TIMEOUT_SECONDS", "5").to_i
          Timeout.timeout(reset_timeout) { @pi.new_session }
        rescue Timeout::Error, PiRpcService::TimeoutError, PiRpcService::ProcessError, PiRpcService::Error
          @pi.stop rescue nil
          @pi.start
        rescue StandardError
          nil
        end

        @last_used_at = Time.current
        yield @pi
      rescue StandardError
        # Restart next time.
        @pi.stop rescue nil
        raise
      end
    end

    def stop!
      @mutex.synchronize do
        @pi.stop rescue nil
      end
    end
  end
end

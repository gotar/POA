# frozen_string_literal: true

Rails.application.configure do
  config.pi_rpc = {
    rpc_timeout: ENV.fetch('PI_RPC_TIMEOUT', 300).to_i,
    startup_timeout: ENV.fetch('PI_RPC_STARTUP_TIMEOUT', 10).to_i,
    max_retry_attempts: ENV.fetch('PI_RPC_MAX_RETRIES', 3).to_i
  }
end
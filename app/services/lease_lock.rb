# frozen_string_literal: true

require "securerandom"

# LeaseLock
#
# Cross-process best-effort lock using runtime_metrics as a shared store.
# Works on SQLite without long-lived transactions.
#
# Similar to QmdHeavyLock but generic (key is provided).
class LeaseLock
  class Busy < StandardError; end

  def self.with_lock(key:, wait_seconds: 0, lease_minutes: 10)
    token = acquire!(key: key, wait_seconds: wait_seconds, lease_minutes: lease_minutes)
    yield
  ensure
    release!(key: key, token: token) if token
  end

  def self.acquire!(key:, wait_seconds: 0, lease_minutes: 10)
    RuntimeMetric.find_or_create_by!(key: key)

    token = SecureRandom.hex(12)
    deadline = wait_seconds.to_i.seconds.from_now

    loop do
      now = Time.current
      expired_before = lease_minutes.to_i.minutes.ago

      updated = RuntimeMetric.where(key: key)
        .where("value IS NULL OR value = '' OR updated_at < ?", expired_before)
        .update_all(value: token, updated_at: now)

      return token if updated == 1

      break if Time.current >= deadline

      sleep 0.5
    end

    raise Busy, "LeaseLock busy for #{key}"
  end

  def self.release!(key:, token:)
    return if token.blank?

    RuntimeMetric.where(key: key, value: token).update_all(value: "", updated_at: Time.current)
  rescue StandardError
    nil
  end
end

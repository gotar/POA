# frozen_string_literal: true

require "securerandom"

# QmdHeavyLock
#
# A cross-process (web + jobs) best-effort lock to serialize expensive QMD operations
# on a Raspberry Pi (or any resource-constrained host).
#
# Uses the runtime_metrics table as a tiny shared coordination store.
# This is intentionally NOT a long DB transaction/row lock (SQLite would deadlock
# / busy-timeout under load). Instead it's a lease-style token with expiry.
class QmdHeavyLock
  KEY = "qmd.heavy_lock"

  class Busy < StandardError; end

  def self.with_lock(wait_seconds: 60, lease_minutes: 10)
    token = acquire!(wait_seconds: wait_seconds, lease_minutes: lease_minutes)
    yield
  ensure
    release!(token) if token
  end

  def self.acquire!(wait_seconds: 60, lease_minutes: 10)
    RuntimeMetric.find_or_create_by!(key: KEY)

    token = SecureRandom.hex(12)
    deadline = wait_seconds.seconds.from_now

    while Time.current < deadline
      now = Time.current
      expired_before = lease_minutes.minutes.ago

      updated = RuntimeMetric.where(key: KEY)
        .where("value IS NULL OR value = '' OR updated_at < ?", expired_before)
        .update_all(value: token, updated_at: now)

      return token if updated == 1

      sleep 0.5
    end

    raise Busy, "QMD heavy lock busy"
  end

  def self.release!(token)
    return if token.blank?

    RuntimeMetric.where(key: KEY, value: token).update_all(value: "", updated_at: Time.current)
  rescue StandardError
    nil
  end
end

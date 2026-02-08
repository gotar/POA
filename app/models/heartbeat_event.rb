# frozen_string_literal: true

class HeartbeatEvent < ApplicationRecord
  validates :started_at, presence: true
  validates :status, presence: true

  def alerts
    JSON.parse(alerts_json.to_s)
  rescue JSON::ParserError
    []
  end
end

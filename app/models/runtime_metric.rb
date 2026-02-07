# frozen_string_literal: true

class RuntimeMetric < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value)
    rec = find_or_initialize_by(key: key)
    rec.value = value
    rec.save!
    rec
  end

  def self.increment(key, by: 1)
    rec = find_or_initialize_by(key: key)
    current = rec.value.to_i
    rec.value = (current + by).to_s
    rec.save!
    rec
  end

  def self.time(key)
    v = get(key)
    return nil if v.blank?

    Time.zone.parse(v)
  rescue StandardError
    nil
  end
end

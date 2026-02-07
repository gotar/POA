# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :project, optional: true

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh, presence: true
  validates :auth, presence: true
end

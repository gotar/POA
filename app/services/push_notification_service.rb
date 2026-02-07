# frozen_string_literal: true

require "webpush"

class PushNotificationService
  class << self
    def enabled?
      ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
    end

    def notify_project(project_id:, title:, body:, url: nil)
      return unless enabled?

      payload = { title: title, body: body, url: url }.compact.to_json

      PushSubscription.where(project_id: project_id).find_each do |sub|
        send_to_subscription(sub, payload)
      end
    end

    private

    def send_to_subscription(sub, payload)
      Webpush.payload_send(
        message: payload,
        endpoint: sub.endpoint,
        p256dh: sub.p256dh,
        auth: sub.auth,
        vapid: {
          subject: ENV.fetch("VAPID_SUBJECT", "mailto:admin@example.com"),
          public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
          private_key: ENV.fetch("VAPID_PRIVATE_KEY")
        }
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
      sub.destroy
    rescue StandardError => e
      Rails.logger.error("WebPush send failed: #{e.class}: #{e.message}")
    end
  end
end

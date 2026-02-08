# frozen_string_literal: true

class PersonalKnowledgeEmbedJob < ApplicationJob
  queue_as :default

  def perform(force: false)
    PersonalKnowledgeService.ensure_setup!

    # Embedding can be very CPU heavy; serialize.
    QmdHeavyLock.with_lock(wait_seconds: 300, lease_minutes: 180) do
      QmdCliService.embed!(force: force)
    end
  end
end

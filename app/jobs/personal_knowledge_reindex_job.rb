# frozen_string_literal: true

class PersonalKnowledgeReindexJob < ApplicationJob
  queue_as :default

  def perform
    PersonalKnowledgeService.ensure_setup!

    # Import pi TUI sessions into the knowledge vault so QMD can index/search them.
    # Best-effort: failures here should not block QMD update.
    PiSessionImportService.import! rescue nil

    # Potentially expensive; serialize with other heavy QMD operations.
    QmdHeavyLock.with_lock(wait_seconds: 300, lease_minutes: 60) do
      QmdCliService.update_and_embed_if_needed!
    end
  end
end

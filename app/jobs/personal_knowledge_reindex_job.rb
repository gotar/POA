# frozen_string_literal: true

class PersonalKnowledgeReindexJob < ApplicationJob
  queue_as :default

  def perform
    PersonalKnowledgeService.ensure_setup!
    QmdCliService.update_and_embed_if_needed!
  end
end

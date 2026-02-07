# frozen_string_literal: true

class PersonalKnowledgeEmbedJob < ApplicationJob
  queue_as :default

  def perform(force: false)
    PersonalKnowledgeService.ensure_setup!
    QmdCliService.embed!(force: force)
  end
end

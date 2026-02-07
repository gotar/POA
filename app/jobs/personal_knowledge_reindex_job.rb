# frozen_string_literal: true

class PersonalKnowledgeReindexJob < ApplicationJob
  queue_as :default

  def perform
    PersonalKnowledgeService.ensure_setup!
    QmdCliService.update!
  end
end

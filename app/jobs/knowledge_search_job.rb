# frozen_string_literal: true

class KnowledgeSearchJob < ApplicationJob
  queue_as :default

  def perform(knowledge_search_id)
    ks = KnowledgeSearch.find(knowledge_search_id)
    token = nil

    begin
      ks.update!(status: "running", started_at: Time.current, error: nil)

      # Run via MCP/CLI with generous timeouts for background searches.
      ENV["QMD_TIMEOUT_SECONDS"] ||= "20"
      ENV["QMD_VSEARCH_TIMEOUT_SECONDS"] ||= "180"
      ENV["QMD_QUERY_TIMEOUT_SECONDS"] ||= "240"

      QmdHeavyLock.with_lock(wait_seconds: 60, lease_minutes: 15) do
        results = QmdCliService.search(ks.query, mode: ks.mode.to_sym, limit: 20)
        ks.update!(status: "completed", results: results, finished_at: Time.current)
      end
    rescue StandardError => e
      begin
        ks.update!(status: "failed", error: e.message, finished_at: Time.current)
      rescue StandardError
        nil
      end
    end
  end

end

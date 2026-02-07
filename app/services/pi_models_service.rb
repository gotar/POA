# frozen_string_literal: true

# Fetches available models from the local `pi` agent (RPC subprocess).
# Uses Rails.cache to avoid spawning pi on every request.
class PiModelsService
  CACHE_KEY_MODELS = "pi_models_service/models/v1"
  CACHE_KEY_DEFAULT = "pi_models_service/default_model/v1"

  class << self
    # Returns models in the format expected by the model picker:
    # [{"label"=>"...", "provider"=>"...", "model"=>"..."}, ...]
    def models(refresh: false)
      if refresh
        Rails.cache.delete(CACHE_KEY_MODELS)
      end

      Rails.cache.fetch(CACHE_KEY_MODELS, expires_in: 10.minutes) do
        fetch_models_from_pi
      end
    rescue StandardError => e
      Rails.logger.error("PiModelsService: failed to fetch models: #{e.class}: #{e.message}")
      Rails.configuration.pi_models || []
    end

    # Returns {provider:, model:} using pi's current default model.
    def default_provider_model(refresh: false)
      if refresh
        Rails.cache.delete(CACHE_KEY_DEFAULT)
      end

      Rails.cache.fetch(CACHE_KEY_DEFAULT, expires_in: 10.minutes) do
        fetch_default_from_pi
      end
    rescue StandardError => e
      Rails.logger.error("PiModelsService: failed to fetch default model: #{e.class}: #{e.message}")
      {
        provider: ENV["PI_PROVIDER"].presence || "opencode",
        model: ENV["PI_MODEL"].presence || "minimax-m2.1-free"
      }
    end

    private

    def fetch_models_from_pi
      pi = PiRpcService.new # don't force provider/model; let pi use its own config
      pi.start

      resp = pi.get_available_models
      models = resp.is_a?(Hash) ? resp.dig("data", "models") : nil
      models = [] unless models.is_a?(Array)

      mapped = models.filter_map do |m|
        next unless m.is_a?(Hash)

        provider = m["provider"].to_s
        model_id = m["id"].to_s
        name = m["name"].presence || model_id
        next if provider.blank? || model_id.blank?

        {
          "label" => "#{name} (#{provider})",
          "provider" => provider,
          "model" => model_id
        }
      end

      mapped.sort_by { |h| [h["provider"].to_s, h["label"].to_s] }
    ensure
      pi.stop rescue nil
    end

    def fetch_default_from_pi
      pi = PiRpcService.new
      pi.start

      resp = pi.get_state
      model = resp.is_a?(Hash) ? resp.dig("data", "model") : nil

      provider = model.is_a?(Hash) ? model["provider"].to_s : ""
      model_id = model.is_a?(Hash) ? (model["id"] || model["model"]).to_s : ""

      if provider.blank? || model_id.blank?
        {
          provider: ENV["PI_PROVIDER"].presence || "opencode",
          model: ENV["PI_MODEL"].presence || "minimax-m2.1-free"
        }
      else
        { provider: provider, model: model_id }
      end
    ensure
      pi.stop rescue nil
    end
  end
end

# frozen_string_literal: true

# Models shown in the chat UI model picker.
# Each entry is { label:, provider:, model: }
#
# You can override in production via PI_MODELS_JSON env var, e.g.
#   PI_MODELS_JSON='[{"label":"GPT-4o mini","provider":"openai","model":"gpt-4o-mini"}]'
Rails.application.configure do
  models = begin
    json = ENV["PI_MODELS_JSON"]
    json.present? ? JSON.parse(json) : nil
  rescue JSON::ParserError
    nil
  end

  config.pi_models = if models.is_a?(Array) && models.any?
    models
  else
    [
      { "label" => "GPT-4o mini (OpenAI)", "provider" => "openai", "model" => "gpt-4o-mini" },
      { "label" => "MiniMax M2.1 Free (OpenCode)", "provider" => "opencode", "model" => "minimax-m2.1-free" },
      { "label" => "Qwen3 Coder Free (OpenRouter)", "provider" => "openrouter", "model" => "qwen/qwen3-coder:free" }
    ]
  end
end

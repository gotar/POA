# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :load_global_diagnostics

  private

  def load_global_diagnostics
    keys = %w[
      diagnostics.qmd_binary
      qmd.last_check_at
      qmd.last_status
      qmd.last_error
    ]

    @global_diagnostics = RuntimeMetric.get_many(keys)
  rescue StandardError
    @global_diagnostics = {}
  end
end

# frozen_string_literal: true

require "site/view/controller"

module Site
  module Views
    class Event2026 < View::Controller
      configure do |config|
        config.template = "wydarzenia/2026"
      end
    end
  end
end

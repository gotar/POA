require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class WhatIs < View::Controller
        configure do |config|
          config.template = "what_is_aikido_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class WhatIs < View::Controller
        configure do |config|
          config.template = "czym_jest_aikido"
        end
      end
    end
  end
end

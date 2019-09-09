require "site/view/controller"
require "site/import"

module Site
  module Views
    module Biographies
      class Osensei < View::Controller
        configure do |config|
          config.template = "osensei"
        end
      end
    end
  end
end


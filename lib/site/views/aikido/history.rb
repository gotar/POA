require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class History < View::Controller
        configure do |config|
          config.template = "historia"
        end
      end
    end
  end
end

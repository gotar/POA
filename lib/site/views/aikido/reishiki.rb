require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class Reishiki < View::Controller
        configure do |config|
          config.template = "aikido/reishiki"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module Biographies
      class Toyoda < View::Controller
        configure do |config|
          config.template = "toyoda"
        end
      end
    end
  end
end

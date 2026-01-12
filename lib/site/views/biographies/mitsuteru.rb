require "site/view/controller"

module Site
  module Views
    module Biographies
      class Mitsuteru < View::Controller
        configure do |config|
          config.template = "mitsuteru"
        end
      end
    end
  end
end

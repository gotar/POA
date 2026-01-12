require "site/view/controller"

module Site
  module Views
    module Biographies
      class Moriteru < View::Controller
        configure do |config|
          config.template = "moriteru"
        end
      end
    end
  end
end

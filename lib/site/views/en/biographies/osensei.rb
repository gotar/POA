require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Biographies
        class Osensei < View::Controller
          configure do |config|
            config.template = "osensei_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

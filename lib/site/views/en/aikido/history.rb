require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class History < View::Controller
          configure do |config|
            config.template = "historia_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class Reishiki < View::Controller
          configure do |config|
            config.template = "aikido/reishiki_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

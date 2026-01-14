require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Biographies
        class Szrajer < View::Controller
          configure do |config|
            config.template = "szrajer_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

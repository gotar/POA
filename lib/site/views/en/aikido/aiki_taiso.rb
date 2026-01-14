require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class AikiTaiso < View::Controller
          configure do |config|
            config.template = "aikido/aiki_taiso_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

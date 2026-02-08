require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class BudoZen < View::Controller
          configure do |config|
            config.template = "aikido/budo_zen_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

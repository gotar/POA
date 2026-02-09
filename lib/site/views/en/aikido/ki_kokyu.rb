require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class KiKokyu < View::Controller
          configure do |config|
            config.template = "aikido/ki_kokyu_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class Benefits < View::Controller
          configure do |config|
            config.template = "korzysci_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

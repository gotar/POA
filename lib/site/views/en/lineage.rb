require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Lineage < View::Controller
        configure do |config|
          config.template = "lineage_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Raciborz < View::Controller
        configure do |config|
          config.template = "raciborz_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

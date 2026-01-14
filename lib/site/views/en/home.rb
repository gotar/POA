require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Home < View::Controller
        configure do |config|
          config.template = "home_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

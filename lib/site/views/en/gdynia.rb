require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Gdynia < View::Controller
        configure do |config|
          config.template = "gdynia_en"
        end
      end
    end
  end
end

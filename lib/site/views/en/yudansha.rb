require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Yudansha < View::Controller
        configure do |config|
          config.template = "yudansha_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Event2026 < View::Controller
        configure do |config|
          config.template = "wydarzenia_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

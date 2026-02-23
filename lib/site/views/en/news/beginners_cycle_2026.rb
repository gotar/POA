require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::BeginnersCycle2026 < View::Controller
        configure do |config|
          config.template = "news/beginners_cycle_2026_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

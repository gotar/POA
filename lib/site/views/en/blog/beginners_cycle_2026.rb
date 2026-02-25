require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::BeginnersCycle2026 < View::Controller
        configure do |config|
          config.template = "blog/beginners_cycle_2026_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

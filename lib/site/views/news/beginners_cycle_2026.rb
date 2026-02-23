require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::BeginnersCycle2026 < View::Controller
      configure do |config|
        config.template = "news/beginners_cycle_2026"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::BeginnersCycle2026 < View::Controller
      configure do |config|
        config.template = "blog/beginners_cycle_2026"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::WinterSeminar2026 < View::Controller
      configure do |config|
        config.template = "blog/winter_seminar_2026"
      end
    end
  end
end

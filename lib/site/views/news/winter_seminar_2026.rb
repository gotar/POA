require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::WinterSeminar2026 < View::Controller
      configure do |config|
        config.template = "news/winter_seminar_2026"
      end
    end
  end
end

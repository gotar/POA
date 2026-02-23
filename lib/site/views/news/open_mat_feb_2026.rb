require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::OpenMatFeb2026 < View::Controller
      configure do |config|
        config.template = "news/open_mat_feb_2026"
      end
    end
  end
end

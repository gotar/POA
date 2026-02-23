require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::OpenMatFeb2026 < View::Controller
        configure do |config|
          config.template = "news/open_mat_feb_2026_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

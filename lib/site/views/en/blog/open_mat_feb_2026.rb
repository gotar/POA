require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::OpenMatFeb2026 < View::Controller
        configure do |config|
          config.template = "blog/open_mat_feb_2026_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

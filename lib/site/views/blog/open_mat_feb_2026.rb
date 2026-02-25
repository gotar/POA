require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::OpenMatFeb2026 < View::Controller
      configure do |config|
        config.template = "blog/open_mat_feb_2026"
      end
    end
  end
end

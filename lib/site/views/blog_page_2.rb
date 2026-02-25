require "site/view/controller"
require "site/import"

module Site
  module Views
    class BlogPage2 < View::Controller
      configure do |config|
        config.template = "blog_page_2"
      end
    end
  end
end

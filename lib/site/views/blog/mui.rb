require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Mui < View::Controller
      configure do |config|
        config.template = "blog/mui"
      end
    end
  end
end

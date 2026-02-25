require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Gaman < View::Controller
      configure do |config|
        config.template = "blog/gaman"
      end
    end
  end
end

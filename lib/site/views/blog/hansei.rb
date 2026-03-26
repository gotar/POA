require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Hansei < View::Controller
      configure do |config|
        config.template = "blog/hansei"
      end
    end
  end
end

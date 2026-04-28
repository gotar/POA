require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Giri < View::Controller
      configure do |config|
        config.template = "blog/giri"
      end
    end
  end
end

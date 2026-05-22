require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Ikigai < View::Controller
      configure do |config|
        config.template = "blog/ikigai"
      end
    end
  end
end

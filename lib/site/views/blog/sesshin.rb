require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Sesshin < View::Controller
      configure do |config|
        config.template = "blog/sesshin"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Kuzushi < View::Controller
      configure do |config|
        config.template = "blog/kuzushi"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Heijoshin < View::Controller
      configure do |config|
        config.template = "blog/heijoshin"
      end
    end
  end
end

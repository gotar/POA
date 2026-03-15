require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Shoshin < View::Controller
      configure do |config|
        config.template = "blog/shoshin"
      end
    end
  end
end

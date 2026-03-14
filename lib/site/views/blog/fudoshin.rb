require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Fudoshin < View::Controller
      configure do |config|
        config.template = "blog/fudoshin"
      end
    end
  end
end

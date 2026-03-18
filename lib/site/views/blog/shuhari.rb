require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Shuhari < View::Controller
      configure do |config|
        config.template = "blog/shuhari"
      end
    end
  end
end

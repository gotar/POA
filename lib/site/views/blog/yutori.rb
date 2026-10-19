require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Yutori < View::Controller
      configure do |config|
        config.template = "blog/yutori"
      end
    end
  end
end

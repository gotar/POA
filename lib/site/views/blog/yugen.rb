require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Yugen < View::Controller
      configure do |config|
        config.template = "blog/yugen"
      end
    end
  end
end

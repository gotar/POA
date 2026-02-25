require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Zanshin < View::Controller
      configure do |config|
        config.template = "blog/zanshin"
      end
    end
  end
end

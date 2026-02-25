require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Zenshin < View::Controller
      configure do |config|
        config.template = "blog/zenshin"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Zenshin < View::Controller
      configure do |config|
        config.template = "news/zenshin"
      end
    end
  end
end

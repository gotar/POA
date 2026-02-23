require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Gaman < View::Controller
      configure do |config|
        config.template = "news/gaman"
      end
    end
  end
end

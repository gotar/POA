require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Kuzushi < View::Controller
      configure do |config|
        config.template = "news/kuzushi"
      end
    end
  end
end

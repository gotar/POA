require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Sesshin < View::Controller
      configure do |config|
        config.template = "news/sesshin"
      end
    end
  end
end

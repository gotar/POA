require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Bushido < View::Controller
      configure do |config|
        config.template = "news/bushido"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class News < View::Controller
      configure do |config|
        config.template = "news"
      end
    end
  end
end

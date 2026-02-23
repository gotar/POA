require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Kaizen < View::Controller
      configure do |config|
        config.template = "news/kaizen"
      end
    end
  end
end

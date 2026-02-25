require "site/view/controller"
require "site/import"

module Site
  module Views
    class NewsPage2 < View::Controller
      configure do |config|
        config.template = "news_page_2"
      end
    end
  end
end

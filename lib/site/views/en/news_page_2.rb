require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class NewsPage2 < View::Controller
        configure do |config|
          config.template = "news_page_2_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

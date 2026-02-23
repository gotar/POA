require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::Zenshin < View::Controller
        configure do |config|
          config.template = "news/zenshin_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

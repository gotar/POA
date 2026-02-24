require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::Sesshin < View::Controller
        configure do |config|
          config.template = "news/sesshin_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

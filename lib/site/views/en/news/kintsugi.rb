require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::Kintsugi < View::Controller
        configure do |config|
          config.template = "news/kintsugi_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

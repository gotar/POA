require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::Kuzushi < View::Controller
        configure do |config|
          config.template = "news/kuzushi_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

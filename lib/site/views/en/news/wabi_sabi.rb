require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class News::WabiSabi < View::Controller
        configure do |config|
          config.template = "news/wabi_sabi_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

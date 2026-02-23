require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::WabiSabi < View::Controller
      configure do |config|
        config.template = "news/wabi_sabi"
      end
    end
  end
end

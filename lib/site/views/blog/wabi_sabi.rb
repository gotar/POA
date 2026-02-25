require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::WabiSabi < View::Controller
      configure do |config|
        config.template = "blog/wabi_sabi"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Hyoshi < View::Controller
      configure do |config|
        config.template = "blog/hyoshi"
      end
    end
  end
end

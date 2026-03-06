require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Hyoshi < View::Controller
        configure do |config|
          config.template = "blog/hyoshi_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

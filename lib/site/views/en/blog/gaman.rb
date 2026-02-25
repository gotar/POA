require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Gaman < View::Controller
        configure do |config|
          config.template = "blog/gaman_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Ukemi < View::Controller
        configure do |config|
          config.template = "blog/ukemi_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Shuhari < View::Controller
        configure do |config|
          config.template = "blog/shuhari_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

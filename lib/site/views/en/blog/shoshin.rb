require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Shoshin < View::Controller
        configure do |config|
          config.template = "blog/shoshin_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Nemawashi < View::Controller
        configure do |config|
          config.template = "blog/nemawashi_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

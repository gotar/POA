require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::StylToyody < View::Controller
        configure do |config|
          config.template = "blog/styl_toyody_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

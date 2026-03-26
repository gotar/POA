require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::IchiGoIchiE < View::Controller
        configure do |config|
          config.template = "blog/ichi_go_ichi_e_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

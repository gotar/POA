require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::AikidoWKazdymWieku < View::Controller
        configure do |config|
          config.template = "blog/aikido_w_kazdym_wieku_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

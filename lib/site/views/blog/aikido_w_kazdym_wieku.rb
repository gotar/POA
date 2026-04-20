require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::AikidoWKazdymWieku < View::Controller
      configure do |config|
        config.template = "blog/aikido_w_kazdym_wieku"
      end
    end
  end
end

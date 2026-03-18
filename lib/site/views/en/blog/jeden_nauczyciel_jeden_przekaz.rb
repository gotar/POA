require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::JedenNauczycielJedenPrzekaz < View::Controller
        configure do |config|
          config.template = "blog/jeden_nauczyciel_jeden_przekaz_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

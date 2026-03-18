require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::JedenNauczycielJedenPrzekaz < View::Controller
      configure do |config|
        config.template = "blog/jeden_nauczyciel_jeden_przekaz"
      end
    end
  end
end

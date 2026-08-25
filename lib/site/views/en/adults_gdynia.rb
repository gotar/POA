require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class AdultsGdynia < View::Controller
        configure do |config|
          config.template = "aikido_dla_doroslych_gdynia_en"
          config.layout = "site_en"
        end
      end
    end
  end
end
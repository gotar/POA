require "site/view/controller"
require "site/import"

module Site
  module Views
    class AdultsGdynia < View::Controller
      configure do |config|
        config.template = "aikido_dla_doroslych_gdynia"
      end
    end
  end
end

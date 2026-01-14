require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class RequirementDan < View::Controller
        configure do |config|
          config.template = "wymagania_egzaminacyjne_dan_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

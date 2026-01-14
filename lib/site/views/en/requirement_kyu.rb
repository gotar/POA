require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class RequirementKyu < View::Controller
        configure do |config|
          config.template = "wymagania_egzaminacyjne_kyu_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

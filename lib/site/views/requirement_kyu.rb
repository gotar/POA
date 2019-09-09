require "site/view/controller"
require "site/import"

module Site
  module Views
    class RequirementKyu < View::Controller
      configure do |config|
        config.template = "wymagania_egzaminacyjne_kyu"
      end
    end
  end
end

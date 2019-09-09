require "site/view/controller"
require "site/import"

module Site
  module Views
    class RequirementDan < View::Controller
      configure do |config|
        config.template = "wymagania_egzaminacyjne_dan"
      end
    end
  end
end


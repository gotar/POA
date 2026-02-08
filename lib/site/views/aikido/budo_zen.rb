require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class BudoZen < View::Controller
        configure do |config|
          config.template = "aikido/budo_zen"
        end
      end
    end
  end
end

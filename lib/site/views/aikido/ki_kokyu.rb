require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class KiKokyu < View::Controller
        configure do |config|
          config.template = "aikido/ki_kokyu"
        end
      end
    end
  end
end

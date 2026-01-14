require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class AikiTaiso < View::Controller
        configure do |config|
          config.template = "aikido/aiki_taiso"
        end
      end
    end
  end
end

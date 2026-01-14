require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Aikido
        class Beginners < View::Controller
          configure do |config|
            config.template = "aikido/dla_poczatkujacych_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

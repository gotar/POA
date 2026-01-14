require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Biographies
        class Mitsuteru < View::Controller
          configure do |config|
            config.template = "mitsuteru_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Biographies
        class Germanov < View::Controller
          configure do |config|
            config.template = "germanov_en"
            config.layout = "site_en"
          end
        end
      end
    end
  end
end

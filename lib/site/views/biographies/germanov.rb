require "site/view/controller"
require "site/import"

module Site
  module Views
    module Biographies
      class Germanov < View::Controller
        configure do |config|
          config.template = "germanov"
        end
      end
    end
  end
end

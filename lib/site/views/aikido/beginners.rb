require "site/view/controller"
require "site/import"

module Site
  module Views
    module Aikido
      class Beginners < View::Controller
        configure do |config|
          config.template = "aikido/dla_poczatkujacych"
        end
      end
    end
  end
end

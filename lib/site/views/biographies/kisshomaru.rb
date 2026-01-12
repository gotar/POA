require "site/view/controller"

module Site
  module Views
    module Biographies
      class Kisshomaru < View::Controller
        configure do |config|
          config.template = "kisshomaru"
        end
      end
    end
  end
end

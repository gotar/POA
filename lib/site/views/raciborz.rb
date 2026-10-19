require "site/view/controller"
require "site/import"

module Site
  module Views
    class Raciborz < View::Controller
      configure do |config|
        config.template = "raciborz"
      end
    end
  end
end

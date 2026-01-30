require "site/view/controller"
require "site/import"

module Site
  module Views
    class Gdynia < View::Controller
      configure do |config|
        config.template = "gdynia"
      end
    end
  end
end

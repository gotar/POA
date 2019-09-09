require "site/view/controller"
require "site/import"

module Site
  module Views
    class Event < View::Controller
      configure do |config|
        config.template = "wydarzenia"
      end
    end
  end
end

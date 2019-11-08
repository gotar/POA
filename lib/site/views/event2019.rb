require "site/view/controller"
require "site/import"

module Site
  module Views
    class Event2019 < View::Controller
      configure do |config|
        config.template = "wydarzenia/2019"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Event2020 < View::Controller
      configure do |config|
        config.template = "wydarzenia/2020"
      end
    end
  end
end

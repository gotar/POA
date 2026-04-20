require "site/view/controller"
require "site/import"

module Site
  module Views
    class TrainingGdynia < View::Controller
      configure do |config|
        config.template = "treningi_aikido_gdynia"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class FirstTrainingGdynia < View::Controller
      configure do |config|
        config.template = "pierwszy_trening_aikido_gdynia"
      end
    end
  end
end

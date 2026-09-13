require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class TrainingGdynia < View::Controller
        configure do |config|
          config.template = "aikido_training_gdynia_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

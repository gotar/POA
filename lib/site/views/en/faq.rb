require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Faq < View::Controller
        configure do |config|
          config.template = "faq_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

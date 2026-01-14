require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Contact < View::Controller
        configure do |config|
          config.template = "contact_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Contact < View::Controller
      configure do |config|
        config.template = "kontakt"
      end
    end
  end
end

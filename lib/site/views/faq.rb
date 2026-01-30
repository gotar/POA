require "site/view/controller"
require "site/import"

module Site
  module Views
    class Faq < View::Controller
      configure do |config|
        config.template = "faq"
      end
    end
  end
end

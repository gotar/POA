require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog < View::Controller
      configure do |config|
        config.template = "blog"
      end
    end
  end
end

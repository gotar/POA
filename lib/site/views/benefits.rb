require "site/view/controller"
require "site/import"

module Site
  module Views
    class Benefits < View::Controller
      configure do |config|
        config.template = "korzysci"
      end
    end
  end
end

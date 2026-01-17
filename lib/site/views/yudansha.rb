require "site/view/controller"
require "site/import"

module Site
  module Views
    class Yudansha < View::Controller
      configure do |config|
        config.template = "yudansha"
      end
    end
  end
end

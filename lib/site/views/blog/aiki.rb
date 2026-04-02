require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Aiki < View::Controller
      configure do |config|
        config.template = "blog/aiki"
      end
    end
  end
end

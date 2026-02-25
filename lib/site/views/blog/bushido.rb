require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Bushido < View::Controller
      configure do |config|
        config.template = "blog/bushido"
      end
    end
  end
end

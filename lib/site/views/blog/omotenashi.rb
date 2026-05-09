require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Omotenashi < View::Controller
      configure do |config|
        config.template = "blog/omotenashi"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Enso < View::Controller
      configure do |config|
        config.template = "blog/enso"
      end
    end
  end
end

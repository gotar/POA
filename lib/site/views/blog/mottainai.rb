require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Mottainai < View::Controller
      configure do |config|
        config.template = "blog/mottainai"
      end
    end
  end
end

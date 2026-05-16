require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Nemawashi < View::Controller
      configure do |config|
        config.template = "blog/nemawashi"
      end
    end
  end
end

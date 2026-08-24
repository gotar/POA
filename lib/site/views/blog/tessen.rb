require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Tessen < View::Controller
      configure do |config|
        config.template = "blog/tessen"
      end
    end
  end
end

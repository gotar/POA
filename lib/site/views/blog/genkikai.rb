require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Genkikai < View::Controller
      configure do |config|
        config.template = "blog/genkikai"
      end
    end
  end
end

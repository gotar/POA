require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Kaizen < View::Controller
      configure do |config|
        config.template = "blog/kaizen"
      end
    end
  end
end

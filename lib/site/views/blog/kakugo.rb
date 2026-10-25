require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Kakugo < View::Controller
      configure do |config|
        config.template = "blog/kakugo"
      end
    end
  end
end

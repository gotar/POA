require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Ninjo < View::Controller
      configure do |config|
        config.template = "blog/ninjo"
      end
    end
  end
end

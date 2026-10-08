require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Awase < View::Controller
      configure do |config|
        config.template = "blog/awase"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Kokyu < View::Controller
      configure do |config|
        config.template = "blog/kokyu"
      end
    end
  end
end

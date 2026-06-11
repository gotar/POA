require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Ukemi < View::Controller
      configure do |config|
        config.template = "blog/ukemi"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::MonoNoAware < View::Controller
      configure do |config|
        config.template = "blog/mono_no_aware"
      end
    end
  end
end

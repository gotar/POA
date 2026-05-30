require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::MonoNoAware < View::Controller
        configure do |config|
          config.template = "blog/mono_no_aware_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

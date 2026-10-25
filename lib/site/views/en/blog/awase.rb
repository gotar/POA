require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::Awase < View::Controller
        configure do |config|
          config.template = "blog/awase_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

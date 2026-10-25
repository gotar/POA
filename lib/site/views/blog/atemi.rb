require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Atemi < View::Controller
      configure do |config|
        config.template = "blog/atemi"
      end
    end
  end
end

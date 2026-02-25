require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Kintsugi < View::Controller
      configure do |config|
        config.template = "blog/kintsugi"
      end
    end
  end
end

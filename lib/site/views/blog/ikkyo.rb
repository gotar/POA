require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Ikkyo < View::Controller
      configure do |config|
        config.template = "blog/ikkyo"
      end
    end
  end
end

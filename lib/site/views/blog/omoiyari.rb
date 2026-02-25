require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Omoiyari < View::Controller
      configure do |config|
        config.template = "blog/omoiyari"
      end
    end
  end
end

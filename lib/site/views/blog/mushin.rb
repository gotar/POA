require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Mushin < View::Controller
      configure do |config|
        config.template = "blog/mushin"
      end
    end
  end
end

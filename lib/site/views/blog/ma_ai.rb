require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::MaAi < View::Controller
      configure do |config|
        config.template = "blog/maai"
      end
    end
  end
end

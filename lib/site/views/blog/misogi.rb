require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Misogi < View::Controller
      configure do |config|
        config.template = "blog/misogi"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::EgzaminWBudo < View::Controller
      configure do |config|
        config.template = "blog/egzamin_w_budo"
      end
    end
  end
end

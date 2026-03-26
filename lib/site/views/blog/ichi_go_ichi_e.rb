require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::IchiGoIchiE < View::Controller
      configure do |config|
        config.template = "blog/ichi_go_ichi_e"
      end
    end
  end
end

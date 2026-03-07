require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::StylToyody < View::Controller
      configure do |config|
        config.template = "blog/styl_toyody"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    # Custom 404 page. GitHub Pages serves this file (with HTTP status 404)
    # for every unknown URL, so it must go through the full PL site layout.
    class NotFound < View::Controller
      configure do |config|
        config.template = "404"
        config.layout = "site"
      end
    end
  end
end

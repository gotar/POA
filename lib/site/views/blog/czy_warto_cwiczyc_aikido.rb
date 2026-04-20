require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::CzyWartoCwiczycAikido < View::Controller
      configure do |config|
        config.template = "blog/czy_warto_cwiczyc_aikido"
      end
    end
  end
end

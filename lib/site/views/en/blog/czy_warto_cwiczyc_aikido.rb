require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::CzyWartoCwiczycAikido < View::Controller
        configure do |config|
          config.template = "blog/czy_warto_cwiczyc_aikido_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

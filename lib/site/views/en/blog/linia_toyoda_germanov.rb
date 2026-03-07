require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::LiniaToyodaGermanov < View::Controller
        configure do |config|
          config.template = "blog/linia_toyoda_germanov_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

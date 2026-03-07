require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::LiniaToyodaGermanov < View::Controller
      configure do |config|
        config.template = "blog/linia_toyoda_germanov"
      end
    end
  end
end

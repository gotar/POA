require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::DrogaIMistrzostwo < View::Controller
        configure do |config|
          config.template = "blog/droga_i_mistrzostwo_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

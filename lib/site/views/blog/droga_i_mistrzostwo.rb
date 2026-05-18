require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::DrogaIMistrzostwo < View::Controller
      configure do |config|
        config.template = "blog/droga_i_mistrzostwo"
      end
    end
  end
end

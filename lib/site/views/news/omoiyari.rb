require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Omoiyari < View::Controller
      configure do |config|
        config.template = "news/omoiyari"
      end
    end
  end
end

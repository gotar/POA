require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Mushin < View::Controller
      configure do |config|
        config.template = "news/mushin"
      end
    end
  end
end

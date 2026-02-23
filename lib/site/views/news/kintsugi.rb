require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::Kintsugi < View::Controller
      configure do |config|
        config.template = "news/kintsugi"
      end
    end
  end
end

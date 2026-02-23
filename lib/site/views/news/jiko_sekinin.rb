require "site/view/controller"
require "site/import"

module Site
  module Views
    class News::JikoSekinin < View::Controller
      configure do |config|
        config.template = "news/jiko_sekinin"
      end
    end
  end
end

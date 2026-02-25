require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::JikoSekinin < View::Controller
      configure do |config|
        config.template = "blog/jiko_sekinin"
      end
    end
  end
end

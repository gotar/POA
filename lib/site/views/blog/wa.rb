require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::Wa < View::Controller
      configure do |config|
        config.template = "blog/wa"
      end
    end
  end
end

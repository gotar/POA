require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::AikidoDlaNastolatkow < View::Controller
      configure do |config|
        config.template = "blog/aikido_dla_nastolatkow"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::AikidoDlaNastolatkow < View::Controller
        configure do |config|
          config.template = "blog/aikido_dla_nastolatkow_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

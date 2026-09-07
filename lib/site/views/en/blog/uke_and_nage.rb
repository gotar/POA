require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      module Blog
        class UkeAndNage < View::Controller
          configure do |config|
            config.layout = "site_en"
            config.template = "blog/uke-and-nage-a-learning-relationship_en"
          end
        end
      end
    end
  end
end

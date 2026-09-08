require "site/view/controller"
require "site/import"

module Site
  module Views
    class En::Blog::UkeAndNage < View::Controller
      configure do |config|
        config.layout = "site_en"
        config.template = "blog/uke-and-nage-a-learning-relationship_en"
      end
    end
  end
end
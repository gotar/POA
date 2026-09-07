require "site/view/controller"
require "site/import"

module Site
  module Views
    class En::Blog::UkeINage < View::Controller
      configure do |config|
        config.layout = "site_en"
        config.template = "blog/uke-i-nage-relacja-ktora-uczy_en"
      end
    end
  end
end

require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::UkeINage < View::Controller
      configure do |config|
        config.template = "blog/uke-i-nage-relacja-ktora-uczy"
      end
    end
  end
end

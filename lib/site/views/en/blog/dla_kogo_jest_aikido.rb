require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::DlaKogoJestAikido < View::Controller
        configure do |config|
          config.template = "blog/dla_kogo_jest_aikido_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

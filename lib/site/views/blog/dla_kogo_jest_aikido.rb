require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::DlaKogoJestAikido < View::Controller
      configure do |config|
        config.template = "blog/dla_kogo_jest_aikido"
      end
    end
  end
end

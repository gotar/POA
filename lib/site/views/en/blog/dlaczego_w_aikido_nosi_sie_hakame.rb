require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::DlaczegoWAikidoNosiSieHakame < View::Controller
        configure do |config|
          config.template = "blog/dlaczego_w_aikido_nosi_sie_hakame_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

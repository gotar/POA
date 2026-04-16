require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::DlaczegoWAikidoNosiSieHakame < View::Controller
      configure do |config|
        config.template = "blog/dlaczego_w_aikido_nosi_sie_hakame"
      end
    end
  end
end

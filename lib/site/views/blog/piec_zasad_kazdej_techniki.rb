require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::PiecZasadKazdejTechniki < View::Controller
      configure do |config|
        config.template = "blog/piec_zasad_kazdej_techniki"
      end
    end
  end
end

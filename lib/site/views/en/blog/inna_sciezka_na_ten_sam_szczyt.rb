require "site/view/controller"
require "site/import"

module Site
  module Views
    module En
      class Blog::InnaSciezkaNaTenSamSzczyt < View::Controller
        configure do |config|
          config.template = "blog/inna_sciezka_na_ten_sam_szczyt_en"
          config.layout = "site_en"
        end
      end
    end
  end
end

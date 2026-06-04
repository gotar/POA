require "site/view/controller"
require "site/import"

module Site
  module Views
    class Blog::InnaSciezkaNaTenSamSzczyt < View::Controller
      configure do |config|
        config.template = "blog/inna_sciezka_na_ten_sam_szczyt"
      end
    end
  end
end

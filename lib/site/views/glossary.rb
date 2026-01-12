require "site/view/controller"
require "site/import"

module Site
  module Views
    class Glossary < View::Controller
      configure do |config|
        config.template = "slowniczek"
      end
    end
  end
end

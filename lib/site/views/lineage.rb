# frozen_string_literal: true

require "site/view/controller"

module Site
  module Views
    class Lineage < View::Controller
      configure do |config|
        config.template = "lineage"
      end
    end
  end
end

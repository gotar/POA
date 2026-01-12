# frozen_string_literal: true

require "site/view/controller"

module Site
  module Views
    module Biographies
      class Ostrowski < View::Controller
        configure do |config|
          config.template = "ostrowski"
        end
      end
    end
  end
end

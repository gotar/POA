# frozen_string_literal: true

require "site/view/controller"

module Site
  module Views
    module Biographies
      class Szrajer < View::Controller
        configure do |config|
          config.template = "szrajer"
        end
      end
    end
  end
end

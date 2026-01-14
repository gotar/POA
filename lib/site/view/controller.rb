# auto_register: false

require "builder"
require "dry/view"
require "site/container"

module Site
  module View
    class Controller < Dry::View
      config.paths = [Container.root.join("templates")]
      config.layout = "site"

      def call(context: nil, **input)
        context ||= Container["view.context"].new

        super(context: context, **input)
      end
    end
  end
end

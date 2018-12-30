require "pathname"
require "dry/monads"
require "dry/monads/result"
require "site/import"

module Site
  class Prepare
    include Dry::Monads::Result::Mixin

    include Import[
      "settings",
    ]

    def call(root)
      Success(root)
    end
  end
end

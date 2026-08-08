require "pathname"
require "dry/monads"
require "dry/monads/result"
require "site/import"

module Site
  class Prepare
    include Dry::Monads::Result::Mixin

    include Import[
      "settings",
      import_files: "importers.files"
    ]

    def call(root)
      import_files.(import_dir_for(root))
      Success(root)
    end

    private

    def import_dir_for(root)
      File.expand_path(settings.import_dir, root)
    end
  end
end

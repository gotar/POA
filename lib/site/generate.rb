require "fileutils"
require "site/import"
require "dry/monads"
require "dry/monads/result"

module Site
  class Generate
    include Dry::Monads::Result::Mixin

    include Import[
      "settings",
      export: "exporters.files",
      home_view: "views.home",
    ]

    def call(root)
      export_dir = File.join(root, settings.export_dir)

      FileUtils.cp_r File.join(root, "assets/images"), File.join(export_dir, "assets/images")

      FileUtils.cp File.join(root, "assets/.nojekyll"), File.join(export_dir, ".nojekyll")
      FileUtils.cp File.join(root, "assets/CNAME"), File.join(export_dir, "CNAME")

      render export_dir, "index.html", home_view

      Success(root)
    end

    private

    def render(export_dir, path, view, **input)
      context = view.class.config.context.new(current_path: path.sub(%r{/index.html$}, ""))

      export.(export_dir, path, view.(context: context, **input))
    end
  end
end

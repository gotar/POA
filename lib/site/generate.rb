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
      contact_view: "views.contact",
      requirement_kyu_view: "views.requirement_kyu",
      requirement_dan_view: "views.requirement_dan",
      toyoda_view: "views.biographies.toyoda",
      osensei_view: "views.biographies.osensei",
      germanov_view: "views.biographies.germanov",
      event_2019_view: "views.event2019",
      event_2020_view: "views.event2020",
      benefits_view: "views.benefits",
      aikido_history_view: "views.aikido.history",
      aikido_about_view: "views.aikido.what_is",
    ]

    def call(root)
      export_dir = File.join(root, settings.export_dir)

      FileUtils.cp_r File.join(root, "assets/images"), File.join(export_dir, "assets/images")
      FileUtils.cp_r File.join(root, "assets/favicons/."), File.join(export_dir)

      FileUtils.cp File.join(root, "assets/.nojekyll"), File.join(export_dir, ".nojekyll")
      FileUtils.cp File.join(root, "assets/CNAME"), File.join(export_dir, "CNAME")

      render export_dir, "index.html", contact_view
      render export_dir, "wymagania_egzaminacyjne/kyu.html", requirement_kyu_view
      render export_dir, "wymagania_egzaminacyjne/dan.html", requirement_dan_view
      render export_dir, "biografie/toyoda.html", toyoda_view
      render export_dir, "biografie/o-sensei.html", osensei_view
      render export_dir, "biografie/germanov.html", germanov_view
      render export_dir, "wydarzenia/2019.html", event_2019_view
      render export_dir, "wydarzenia/2020.html", event_2020_view
      render export_dir, "aikido/korzysci.html", benefits_view
      render export_dir, "aikido/historia.html", aikido_history_view
      render export_dir, "aikido/czym_jest.html", aikido_about_view

      Success(root)
    end

    private

    def render(export_dir, path, view, **input)
      context = view.class.config.context.new(current_path: path.sub(%r{/index.html$}, ""))

      export.(export_dir, path, view.(context: context, **input))
    end
  end
end

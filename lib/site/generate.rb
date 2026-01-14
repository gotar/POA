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
      contact_view: "views.contact",
      glossary_view: "views.glossary",
      requirement_kyu_view: "views.requirement_kyu",
      requirement_dan_view: "views.requirement_dan",
      toyoda_view: "views.biographies.toyoda",
      osensei_view: "views.biographies.osensei",
      germanov_view: "views.biographies.germanov",
      szrajer_view: "views.biographies.szrajer",
      ostrowski_view: "views.biographies.ostrowski",
      kisshomaru_view: "views.biographies.kisshomaru",
      moriteru_view: "views.biographies.moriteru",
      mitsuteru_view: "views.biographies.mitsuteru",
      event_2026_view: "views.event2026",
      benefits_view: "views.benefits",
      aikido_history_view: "views.aikido.history",
      aikido_about_view: "views.aikido.what_is",
      aikido_aiki_taiso_view: "views.aikido.aiki_taiso",
      aikido_reishiki_view: "views.aikido.reishiki",
      aikido_beginners_view: "views.aikido.beginners",
      lineage_view: "views.lineage",
    ]

    def call(root)
      export_dir = File.join(root, settings.export_dir)

      FileUtils.mkdir_p File.join(export_dir, "assets")
      FileUtils.cp_r File.join(root, "assets/images"), File.join(export_dir, "assets/images")
      FileUtils.cp_r File.join(root, "assets/favicons/."), File.join(export_dir)
      FileUtils.cp File.join(root, "assets/style.css"), File.join(export_dir, "assets/style.css")

      FileUtils.cp File.join(root, "assets/.nojekyll"), File.join(export_dir, ".nojekyll")
      FileUtils.cp File.join(root, "assets/CNAME"), File.join(export_dir, "CNAME")

      render export_dir, "index.html", home_view
      render export_dir, "kontakt.html", contact_view
      render export_dir, "slowniczek.html", glossary_view
      render export_dir, "wymagania_egzaminacyjne/kyu.html", requirement_kyu_view
      render export_dir, "wymagania_egzaminacyjne/dan.html", requirement_dan_view
      render export_dir, "biografie/toyoda.html", toyoda_view
      render export_dir, "biografie/o-sensei.html", osensei_view
      render export_dir, "biografie/germanov.html", germanov_view
      render export_dir, "biografie/szrajer.html", szrajer_view
      render export_dir, "biografie/ostrowski.html", ostrowski_view
      render export_dir, "biografie/kisshomaru.html", kisshomaru_view
      render export_dir, "biografie/moriteru.html", moriteru_view
      render export_dir, "biografie/mitsuteru.html", mitsuteru_view
      render export_dir, "wydarzenia/2026.html", event_2026_view
      render export_dir, "aikido/korzysci.html", benefits_view
      render export_dir, "aikido/historia.html", aikido_history_view
      render export_dir, "aikido/czym_jest.html", aikido_about_view
      render export_dir, "aikido/aiki_taiso.html", aikido_aiki_taiso_view
      render export_dir, "aikido/reishiki.html", aikido_reishiki_view
      render export_dir, "aikido/dla_poczatkujacych.html", aikido_beginners_view
      render export_dir, "lineage.html", lineage_view

      Success(root)
    end

    private

    def render(export_dir, path, view, **input)
      base_context = Site::Container["view.context"]
      context = base_context.new(current_path: path.sub(%r{/index.html$}, ""))

      export.(export_dir, path, view.(context: context, **input))
    end
  end
end

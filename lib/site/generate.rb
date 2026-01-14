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
      home_en_view: "views.en.home",
      contact_view: "views.contact",
      contact_en_view: "views.en.contact",
      what_is_en_view: "views.en.what_is",
      glossary_view: "views.glossary",
      glossary_en_view: "views.en.glossary",
      requirement_kyu_view: "views.requirement_kyu",
      requirement_dan_view: "views.requirement_dan",
      requirement_kyu_en_view: "views.en.requirement_kyu",
      requirement_dan_en_view: "views.en.requirement_dan",
      toyoda_view: "views.biographies.toyoda",
      osensei_view: "views.biographies.osensei",
      germanov_view: "views.biographies.germanov",
      szrajer_view: "views.biographies.szrajer",
      ostrowski_view: "views.biographies.ostrowski",
      kisshomaru_view: "views.biographies.kisshomaru",
      moriteru_view: "views.biographies.moriteru",
      mitsuteru_view: "views.biographies.mitsuteru",
      toyoda_en_view: "views.en.biographies.toyoda",
      osensei_en_view: "views.en.biographies.osensei",
      germanov_en_view: "views.en.biographies.germanov",
      szrajer_en_view: "views.en.biographies.szrajer",
      ostrowski_en_view: "views.en.biographies.ostrowski",
      kisshomaru_en_view: "views.en.biographies.kisshomaru",
      moriteru_en_view: "views.en.biographies.moriteru",
      mitsuteru_en_view: "views.en.biographies.mitsuteru",
      event_2026_view: "views.event2026",
      event_2026_en_view: "views.en.event2026",
      benefits_view: "views.benefits",
      aikido_history_view: "views.aikido.history",
      aikido_about_view: "views.aikido.what_is",
      aikido_aiki_taiso_view: "views.aikido.aiki_taiso",
      aikido_reishiki_view: "views.aikido.reishiki",
      aikido_beginners_view: "views.aikido.beginners",
      aikido_history_en_view: "views.en.aikido.history",
      aikido_aiki_taiso_en_view: "views.en.aikido.aiki_taiso",
      aikido_reishiki_en_view: "views.en.aikido.reishiki",
      aikido_beginners_en_view: "views.en.aikido.beginners",
      aikido_benefits_en_view: "views.en.aikido.benefits",
      lineage_view: "views.lineage",
      lineage_en_view: "views.en.lineage",
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
      render export_dir, "en/index.html", home_en_view
      render export_dir, "kontakt.html", contact_view
      render export_dir, "en/contact.html", contact_en_view
      render export_dir, "en/aikido/what_is.html", what_is_en_view
      render export_dir, "slowniczek.html", glossary_view
      render export_dir, "en/glossary.html", glossary_en_view
      render export_dir, "wymagania_egzaminacyjne/kyu.html", requirement_kyu_view
      render export_dir, "wymagania_egzaminacyjne/dan.html", requirement_dan_view
      render export_dir, "en/requirements/kyu.html", requirement_kyu_en_view
      render export_dir, "en/requirements/dan.html", requirement_dan_en_view
      render export_dir, "biografie/toyoda.html", toyoda_view
      render export_dir, "biografie/o-sensei.html", osensei_view
      render export_dir, "biografie/germanov.html", germanov_view
      render export_dir, "biografie/szrajer.html", szrajer_view
      render export_dir, "biografie/ostrowski.html", ostrowski_view
      render export_dir, "biografie/kisshomaru.html", kisshomaru_view
      render export_dir, "biografie/moriteru.html", moriteru_view
      render export_dir, "biografie/mitsuteru.html", mitsuteru_view
      render export_dir, "en/biographies/toyoda.html", toyoda_en_view
      render export_dir, "en/biographies/o-sensei.html", osensei_en_view
      render export_dir, "en/biographies/germanov.html", germanov_en_view
      render export_dir, "en/biographies/szrajer.html", szrajer_en_view
      render export_dir, "en/biographies/ostrowski.html", ostrowski_en_view
      render export_dir, "en/biographies/kisshomaru.html", kisshomaru_en_view
      render export_dir, "en/biographies/moriteru.html", moriteru_en_view
      render export_dir, "en/biographies/mitsuteru.html", mitsuteru_en_view
      render export_dir, "wydarzenia/2026.html", event_2026_view
      render export_dir, "en/events/2026.html", event_2026_en_view
      render export_dir, "aikido/korzysci.html", benefits_view
      render export_dir, "aikido/historia.html", aikido_history_view
      render export_dir, "aikido/czym_jest.html", aikido_about_view
      render export_dir, "aikido/aiki_taiso.html", aikido_aiki_taiso_view
      render export_dir, "aikido/reishiki.html", aikido_reishiki_view
      render export_dir, "aikido/dla_poczatkujacych.html", aikido_beginners_view
      render export_dir, "en/aikido/history.html", aikido_history_en_view
      render export_dir, "en/aikido/benefits.html", aikido_benefits_en_view
      render export_dir, "en/aikido/aiki_taiso.html", aikido_aiki_taiso_en_view
      render export_dir, "en/aikido/reishiki.html", aikido_reishiki_en_view
      render export_dir, "en/aikido/beginners.html", aikido_beginners_en_view
      render export_dir, "lineage.html", lineage_view
      render export_dir, "en/lineage.html", lineage_en_view

      Success(root)
    end

    private

    def render(export_dir, path, view, **input)
      base_context = Site::Container["view.context"]
      processed_path = path.sub(%r{/index.html$}, "")
      context = base_context.new(current_path: processed_path)

      export.(export_dir, path, view.(context: context, **input))
    end
  end
end

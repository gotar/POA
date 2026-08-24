require "fileutils"
require "site/import"
require "site/sitemap"
require "dry/monads"
require "dry/monads/result"

module Site
  class Generate
    include Dry::Monads::Result::Mixin

    include Import["settings", export: "exporters.files"]

    # Declarative page map: output path => dry-system view key. Adding a
    # page means adding one line here (plus the SEO data entry and the
    # regenerated test/fixtures/seo_snapshot.json).
PAGES = {
  "index.html" => "views.home",
  "en/index.html" => "views.en.home",
  "kontakt.html" => "views.contact",
  "en/contact.html" => "views.en.contact",
  "en/aikido/what_is.html" => "views.en.what_is",
  "slowniczek.html" => "views.glossary",
  "en/glossary.html" => "views.en.glossary",
  "wymagania_egzaminacyjne/kyu.html" => "views.requirement_kyu",
  "wymagania_egzaminacyjne/dan.html" => "views.requirement_dan",
  "en/requirements/kyu.html" => "views.en.requirement_kyu",
  "en/requirements/dan.html" => "views.en.requirement_dan",
  "biografie/toyoda.html" => "views.biographies.toyoda",
  "biografie/o-sensei.html" => "views.biographies.osensei",
  "biografie/germanov.html" => "views.biographies.germanov",
  "biografie/szrajer.html" => "views.biographies.szrajer",
  "biografie/ostrowski.html" => "views.biographies.ostrowski",
  "biografie/kisshomaru.html" => "views.biographies.kisshomaru",
  "biografie/moriteru.html" => "views.biographies.moriteru",
  "biografie/mitsuteru.html" => "views.biographies.mitsuteru",
  "en/biographies/toyoda.html" => "views.en.biographies.toyoda",
  "en/biographies/o-sensei.html" => "views.en.biographies.osensei",
  "en/biographies/germanov.html" => "views.en.biographies.germanov",
  "en/biographies/szrajer.html" => "views.en.biographies.szrajer",
  "en/biographies/ostrowski.html" => "views.en.biographies.ostrowski",
  "en/biographies/kisshomaru.html" => "views.en.biographies.kisshomaru",
  "en/biographies/moriteru.html" => "views.en.biographies.moriteru",
  "en/biographies/mitsuteru.html" => "views.en.biographies.mitsuteru",
  "wydarzenia/2026.html" => "views.event2026",
  "en/events/2026.html" => "views.en.event2026",
  "aikido/korzysci.html" => "views.benefits",
  "aikido/historia.html" => "views.aikido.history",
  "aikido/czym_jest.html" => "views.aikido.what_is",
  "aikido/aiki_taiso.html" => "views.aikido.aiki_taiso",
  "aikido/reishiki.html" => "views.aikido.reishiki",
  "aikido/budo_zen.html" => "views.aikido.budo_zen",
  "aikido/ki_kokyu.html" => "views.aikido.ki_kokyu",
  "aikido/dla_poczatkujacych.html" => "views.aikido.beginners",
  "en/aikido/history.html" => "views.en.aikido.history",
  "en/aikido/benefits.html" => "views.en.aikido.benefits",
  "en/aikido/aiki_taiso.html" => "views.en.aikido.aiki_taiso",
  "en/aikido/reishiki.html" => "views.en.aikido.reishiki",
  "en/aikido/budo_zen.html" => "views.en.aikido.budo_zen",
  "en/aikido/ki_kokyu.html" => "views.en.aikido.ki_kokyu",
  "en/aikido/beginners.html" => "views.en.aikido.beginners",
  "lineage.html" => "views.lineage",
  "en/lineage.html" => "views.en.lineage",
  "yudansha.html" => "views.yudansha",
  "en/yudansha.html" => "views.en.yudansha",
  "gdynia.html" => "views.gdynia",
  "en/gdynia.html" => "views.en.gdynia",
  "treningi-aikido-gdynia.html" => "views.training_gdynia",
  "pierwszy-trening-aikido-gdynia.html" => "views.first_training_gdynia",
  "aikido-dla-doroslych-gdynia.html" => "views.adults_gdynia",
  "faq.html" => "views.faq",
  "en/faq.html" => "views.en.faq",
  "blog/bushido-droga-wojownika.html" => "views.blog.bushido",
  "blog/kaizen-ciagle-doskonalenie.html" => "views.blog.kaizen",
  "blog/gaman-wytrwalosc.html" => "views.blog.gaman",
  "blog/kintsugi-zlota-naprawa.html" => "views.blog.kintsugi",
  "blog/wabi-sabi-piekno-niedoskonalosci.html" => "views.blog.wabi_sabi",
  "blog/mushin-umysl-bez-umyslu.html" => "views.blog.mushin",
  "blog/sesshin-gleboka-praktyka.html" => "views.blog.sesshin",
  "blog/zenshin-pelne-zaangazowanie.html" => "views.blog.zenshin",
  "blog/zanshin-czujnosc-po-technice.html" => "views.blog.zanshin",
  "blog/enso-krag-obecnosci.html" => "views.blog.enso",
  "blog/hyoshi-rytm-timing-jednosci-ruchu.html" => "views.blog.hyoshi",
  "blog/fudoshin-niewzruszony-umysl.html" => "views.blog.fudoshin",
  "blog/shoshin-umysl-poczatkujacego.html" => "views.blog.shoshin",
  "blog/shuhari-etapy-dojrzewania-w-treningu.html" => "views.blog.shuhari",
  "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html" => "views.blog.hansei",
  "blog/aiki-harmonia-w-dzialaniu.html" => "views.blog.aiki",
  "blog/wa-harmonia-bez-uleglosci.html" => "views.blog.wa",
  "blog/giri-obowiazek-bez-wymowek.html" => "views.blog.giri",
  "blog/droga-i-mistrzostwo.html" => "views.blog.droga_i_mistrzostwo",
  "blog/ikigai-sens-regularnej-praktyki.html" => "views.blog.ikigai",
  "blog/mottainai-nie-marnuj-tego-co-moze-cie-nauczyc.html" => "views.blog.mottainai",
  "blog/mono-no-aware-czulosc-wobec-przemijania.html" => "views.blog.mono_no_aware",
  "blog/ikkyo-pierwsza-nauka-ktora-nie-konczy-sie-nigdy.html" => "views.blog.ikkyo",
  "blog/yugen-glebia-ktorej-nie-da-sie-splaszczyc.html" => "views.blog.yugen",
  "blog/egzamin-w-budo-pokaz-drogi-nie-wystep.html" => "views.blog.egzamin_w_budo",
  "blog/ukemi-bezpiecznie-upasc-zachowac-strukture-wrocic-do-dzialania.html" => "views.blog.ukemi",
  "blog/tessen-miecz-bez-miecza-ktory-porzadkuje-ruch.html" => "views.blog.tessen",
  "blog/genkikai-cialo-ktore-wraca-na-miejsce.html" => "views.blog.genkikai",
  "blog/inna-sciezka-na-ten-sam-szczyt.html" => "views.blog.inna_sciezka_na_ten_sam_szczyt",
  "blog/ninjo-ludzkie-uczucia-bez-utraty-kierunku.html" => "views.blog.ninjo",
  "blog/omotenashi-goscinnosc-ktora-buduje-dojo.html" => "views.blog.omotenashi",
  "blog/nemawashi-przygotowanie-gruntu-przed-dzialaniem.html" => "views.blog.nemawashi",
  "blog/misogi-oczyszczenie-przez-praktyke.html" => "views.blog.misogi",
  "blog/5-zasad-kazdej-techniki.html" => "views.blog.piec_zasad_kazdej_techniki",
  "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html" => "views.blog.ichi_go_ichi_e",
  "blog/jeden-nauczyciel-jeden-przekaz.html" => "views.blog.jeden_nauczyciel_jeden_przekaz",
  "blog/dlaczego-w-aikido-nosi-sie-hakame.html" => "views.blog.dlaczego_w_aikido_nosi_sie_hakame",
  "blog/dla-kogo-jest-aikido.html" => "views.blog.dla_kogo_jest_aikido",
  "blog/czy-warto-cwiczyc-aikido.html" => "views.blog.czy_warto_cwiczyc_aikido",
  "blog/aikido-w-kazdym-wieku.html" => "views.blog.aikido_w_kazdym_wieku",
  "blog/aikido-dla-nastolatkow.html" => "views.blog.aikido_dla_nastolatkow",
  "blog/styl-aikido-fumio-toyody-technika-i-zen.html" => "views.blog.styl_toyody",
  "blog/linia-toyoda-germanov-jak-cwiczymy.html" => "views.blog.linia_toyoda_germanov",
  "blog/omoiyari-uwazna-troska.html" => "views.blog.omoiyari",
  "blog/jiko-sekinin-odpowiedzialnosc-osobista.html" => "views.blog.jiko_sekinin",
  "blog/kuzushi-kontrolowana-nierownowaga.html" => "views.blog.kuzushi",
  "en/blog/bushido-way-of-the-warrior.html" => "views.en.blog.bushido",
  "en/blog/kaizen-continuous-improvement.html" => "views.en.blog.kaizen",
  "en/blog/gaman-endurance-and-composure.html" => "views.en.blog.gaman",
  "en/blog/kintsugi-golden-repair.html" => "views.en.blog.kintsugi",
  "en/blog/wabi-sabi-beauty-of-imperfection.html" => "views.en.blog.wabi_sabi",
  "en/blog/mushin-no-mind.html" => "views.en.blog.mushin",
  "en/blog/sesshin-deep-practice.html" => "views.en.blog.sesshin",
  "en/blog/zenshin-full-commitment.html" => "views.en.blog.zenshin",
  "en/blog/zanshin-awareness-after-execution.html" => "views.en.blog.zanshin",
  "en/blog/enso-circle-of-presence.html" => "views.en.blog.enso",
  "en/blog/hyoshi-timing-reveals-unity-of-movement.html" => "views.en.blog.hyoshi",
  "en/blog/fudoshin-immovable-mind.html" => "views.en.blog.fudoshin",
  "en/blog/shoshin-beginners-mind.html" => "views.en.blog.shoshin",
  "en/blog/shuhari-stages-of-maturation-in-training.html" => "views.en.blog.shuhari",
  "en/blog/hansei-honest-self-reflection-without-excuses.html" => "views.en.blog.hansei",
  "en/blog/aiki-harmony-in-action.html" => "views.en.blog.aiki",
  "en/blog/wa-harmony-without-submission.html" => "views.en.blog.wa",
  "en/blog/giri-duty-without-excuses.html" => "views.en.blog.giri",
  "en/blog/the-path-and-mastery.html" => "views.en.blog.droga_i_mistrzostwo",
  "en/blog/ikigai-the-reason-to-return-to-practice.html" => "views.en.blog.ikigai",
  "en/blog/mottainai-do-not-waste-what-can-teach-you.html" => "views.en.blog.mottainai",
  "en/blog/mono-no-aware-sensitivity-to-impermanence.html" => "views.en.blog.mono_no_aware",
  "en/blog/ikkyo-the-first-teaching-that-never-ends.html" => "views.en.blog.ikkyo",
  "en/blog/yugen-depth-that-cannot-be-flattened.html" => "views.en.blog.yugen",
  "en/blog/exams-in-budo-showing-the-road-not-performing.html" => "views.en.blog.egzamin_w_budo",
  "en/blog/ukemi-falling-safely-keeping-structure-returning-to-action.html" => "views.en.blog.ukemi",
  "en/blog/tessen-the-sword-that-is-not-a-sword.html" => "views.en.blog.tessen",
  "en/blog/genkikai-the-body-that-returns-to-order.html" => "views.en.blog.genkikai",
  "en/blog/another-path-to-the-same-summit.html" => "views.en.blog.inna_sciezka_na_ten_sam_szczyt",
  "en/blog/ninjo-human-feeling-without-losing-direction.html" => "views.en.blog.ninjo",
  "en/blog/omotenashi-hospitality-that-builds-the-dojo.html" => "views.en.blog.omotenashi",
  "en/blog/nemawashi-laying-groundwork-before-action.html" => "views.en.blog.nemawashi",
  "en/blog/misogi-purification-through-practice.html" => "views.en.blog.misogi",
  "en/blog/five-principles-behind-every-technique.html" => "views.en.blog.piec_zasad_kazdej_techniki",
  "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html" => "views.en.blog.ichi_go_ichi_e",
  "en/blog/one-teacher-one-transmission.html" => "views.en.blog.jeden_nauczyciel_jeden_przekaz",
  "en/blog/why-aikido-practitioners-wear-hakama.html" => "views.en.blog.dlaczego_w_aikido_nosi_sie_hakame",
  "en/blog/who-is-aikido-for.html" => "views.en.blog.dla_kogo_jest_aikido",
  "en/blog/is-aikido-worth-practicing.html" => "views.en.blog.czy_warto_cwiczyc_aikido",
  "en/blog/aikido-at-every-age.html" => "views.en.blog.aikido_w_kazdym_wieku",
  "en/blog/aikido-for-teenagers.html" => "views.en.blog.aikido_dla_nastolatkow",
  "en/blog/toyoda-aikido-style-technique-and-zen.html" => "views.en.blog.styl_toyody",
  "en/blog/toyoda-germanov-lineage-how-we-train.html" => "views.en.blog.linia_toyoda_germanov",
  "en/blog/omoiyari-considerate-compassion.html" => "views.en.blog.omoiyari",
  "en/blog/jiko-sekinin-personal-responsibility.html" => "views.en.blog.jiko_sekinin",
  "en/blog/kuzushi-controlled-imbalance.html" => "views.en.blog.kuzushi",
  "404.html" => "views.not_found",
}.freeze
    def call(root)
      export_dir = export_dir_for(root)
      @rendered_pages = []

      copy_static_assets(root, export_dir)

      # Blog index pages first: resolving the blog views defines the
      # Site::Views::Blog namespace that article views inherit from.
      render_blog_index_pages(export_dir)

      PAGES.each do |path, view_key|
        render_page(export_dir, path, view_key)
      end

      File.write(
        File.join(export_dir, "sitemap.xml"),
        Site::Sitemap.new.call(@rendered_pages)
      )

      Success(root)
    end

    private

    def copy_static_assets(root, export_dir)
      FileUtils.mkdir_p File.join(export_dir, "assets")
      FileUtils.cp_r File.join(root, "assets/images"), File.join(export_dir, "assets/images")
      FileUtils.cp_r File.join(root, "assets/favicons/."), File.join(export_dir)
      FileUtils.cp File.join(root, "assets/style.css"), File.join(export_dir, "assets/style.css")
      FileUtils.cp File.join(root, "assets/app.js"), File.join(export_dir, "assets/app.js")
      FileUtils.cp File.join(root, "assets/manifest.json"), File.join(export_dir, "assets/manifest.json")
      FileUtils.cp File.join(root, "assets/robots.txt"), File.join(export_dir, "robots.txt")

      FileUtils.cp File.join(root, "assets/.nojekyll"), File.join(export_dir, ".nojekyll")
      FileUtils.cp File.join(root, "assets/CNAME"), File.join(export_dir, "CNAME")
    end

    def render_blog_index_pages(export_dir)
      context = Site::Container["view.context"]

      (1..context.blog_total_pages(language: "pl")).each do |page|
        path = page == 1 ? "blog.html" : "blog-#{page}.html"
        render export_dir, path, Site::Container["views.blog"]
      end

      (1..context.blog_total_pages(language: "en")).each do |page|
        path = page == 1 ? "en/blog.html" : "en/blog-#{page}.html"
        render export_dir, path, Site::Container["views.en.blog"]
      end
    end

    def export_dir_for(root)
      File.expand_path(settings.export_dir, root)
    end

    def render_page(export_dir, path, view_key)
      render export_dir, path, Site::Container[view_key]
    end

    def render(export_dir, path, view, **input)
      base_context = Site::Container["view.context"]
      processed_path = path.sub(%r{(?:^|/)index.html$}, "")
      context = base_context.new(current_path: processed_path, root: Site::Container.config.root)

      @rendered_pages << [processed_path, view]
      export.(export_dir, path, view.(context: context, **input))
    end
  end
end

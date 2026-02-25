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
      aikido_budo_zen_view: "views.aikido.budo_zen",
      aikido_ki_kokyu_view: "views.aikido.ki_kokyu",
      aikido_history_en_view: "views.en.aikido.history",
      aikido_ki_kokyu_en_view: "views.en.aikido.ki_kokyu",
      aikido_aiki_taiso_en_view: "views.en.aikido.aiki_taiso",
      aikido_reishiki_en_view: "views.en.aikido.reishiki",
      aikido_beginners_en_view: "views.en.aikido.beginners",
      aikido_budo_zen_en_view: "views.en.aikido.budo_zen",
      aikido_benefits_en_view: "views.en.aikido.benefits",
      lineage_view: "views.lineage",
      lineage_en_view: "views.en.lineage",
      yudansha_view: "views.yudansha",
      yudansha_en_view: "views.en.yudansha",
      gdynia_view: "views.gdynia",
      gdynia_en_view: "views.en.gdynia",
      faq_view: "views.faq",
      faq_en_view: "views.en.faq",
      blog_view: "views.blog",
      blog_page_2_view: "views.blog_page_2",
      blog_en_view: "views.en.blog",
      blog_en_page_2_view: "views.en.blog_page_2",
      blog_bushido_view: "views.blog.bushido",
      blog_kaizen_view: "views.blog.kaizen",
      blog_gaman_view: "views.blog.gaman",
      blog_kintsugi_view: "views.blog.kintsugi",
      blog_wabi_sabi_view: "views.blog.wabi_sabi",
      blog_mushin_view: "views.blog.mushin",
      blog_sesshin_view: "views.blog.sesshin",
      blog_zenshin_view: "views.blog.zenshin",
      blog_omoiyari_view: "views.blog.omoiyari",
      blog_jiko_sekinin_view: "views.blog.jiko_sekinin",
      blog_kuzushi_view: "views.blog.kuzushi",
      blog_bushido_en_view: "views.en.blog.bushido",
      blog_kaizen_en_view: "views.en.blog.kaizen",
      blog_gaman_en_view: "views.en.blog.gaman",
      blog_kintsugi_en_view: "views.en.blog.kintsugi",
      blog_wabi_sabi_en_view: "views.en.blog.wabi_sabi",
      blog_mushin_en_view: "views.en.blog.mushin",
      blog_sesshin_en_view: "views.en.blog.sesshin",
      blog_zenshin_en_view: "views.en.blog.zenshin",
      blog_omoiyari_en_view: "views.en.blog.omoiyari",
      blog_jiko_sekinin_en_view: "views.en.blog.jiko_sekinin",
      blog_kuzushi_en_view: "views.en.blog.kuzushi",
    ]

    def call(root)
      export_dir = File.join(root, settings.export_dir)

      FileUtils.mkdir_p File.join(export_dir, "assets")
      FileUtils.cp_r File.join(root, "assets/images"), File.join(export_dir, "assets/images")
      FileUtils.cp_r File.join(root, "assets/favicons/."), File.join(export_dir)
      FileUtils.cp File.join(root, "assets/style.css"), File.join(export_dir, "assets/style.css")
      FileUtils.cp File.join(root, "assets/manifest.json"), File.join(export_dir, "assets/manifest.json")
      FileUtils.cp File.join(root, "assets/robots.txt"), File.join(export_dir, "robots.txt")
      FileUtils.cp File.join(root, "assets/sitemap.xml"), File.join(export_dir, "sitemap.xml")

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
      render export_dir, "aikido/budo_zen.html", aikido_budo_zen_view
      render export_dir, "aikido/ki_kokyu.html", aikido_ki_kokyu_view
      render export_dir, "aikido/dla_poczatkujacych.html", aikido_beginners_view
      render export_dir, "en/aikido/history.html", aikido_history_en_view
      render export_dir, "en/aikido/benefits.html", aikido_benefits_en_view
      render export_dir, "en/aikido/aiki_taiso.html", aikido_aiki_taiso_en_view
      render export_dir, "en/aikido/reishiki.html", aikido_reishiki_en_view
      render export_dir, "en/aikido/budo_zen.html", aikido_budo_zen_en_view
      render export_dir, "en/aikido/ki_kokyu.html", aikido_ki_kokyu_en_view
      render export_dir, "en/aikido/beginners.html", aikido_beginners_en_view
      render export_dir, "lineage.html", lineage_view
      render export_dir, "en/lineage.html", lineage_en_view
      render export_dir, "yudansha.html", yudansha_view
      render export_dir, "en/yudansha.html", yudansha_en_view
      render export_dir, "gdynia.html", gdynia_view
      render export_dir, "en/gdynia.html", gdynia_en_view
      render export_dir, "faq.html", faq_view
      render export_dir, "en/faq.html", faq_en_view
      render export_dir, "blog.html", blog_view
      render export_dir, "blog-2.html", blog_page_2_view
      render export_dir, "en/blog.html", blog_en_view
      render export_dir, "en/blog-2.html", blog_en_page_2_view
      render export_dir, "blog/bushido-droga-wojownika.html", blog_bushido_view
      render export_dir, "blog/kaizen-ciagle-doskonalenie.html", blog_kaizen_view
      render export_dir, "blog/gaman-wytrwalosc.html", blog_gaman_view
      render export_dir, "blog/kintsugi-zlota-naprawa.html", blog_kintsugi_view
      render export_dir, "blog/wabi-sabi-piekno-niedoskonalosci.html", blog_wabi_sabi_view
      render export_dir, "blog/mushin-umysl-bez-umyslu.html", blog_mushin_view
      render export_dir, "blog/sesshin-gleboka-praktyka.html", blog_sesshin_view
      render export_dir, "blog/zenshin-pelne-zaangazowanie.html", blog_zenshin_view
      render export_dir, "blog/omoiyari-uwazna-troska.html", blog_omoiyari_view
      render export_dir, "blog/jiko-sekinin-odpowiedzialnosc-osobista.html", blog_jiko_sekinin_view
      render export_dir, "blog/kuzushi-kontrolowana-nierownowaga.html", blog_kuzushi_view
      render export_dir, "en/blog/bushido-way-of-the-warrior.html", blog_bushido_en_view
      render export_dir, "en/blog/kaizen-continuous-improvement.html", blog_kaizen_en_view
      render export_dir, "en/blog/gaman-endurance-and-composure.html", blog_gaman_en_view
      render export_dir, "en/blog/kintsugi-golden-repair.html", blog_kintsugi_en_view
      render export_dir, "en/blog/wabi-sabi-beauty-of-imperfection.html", blog_wabi_sabi_en_view
      render export_dir, "en/blog/mushin-no-mind.html", blog_mushin_en_view
      render export_dir, "en/blog/sesshin-deep-practice.html", blog_sesshin_en_view
      render export_dir, "en/blog/zenshin-full-commitment.html", blog_zenshin_en_view
      render export_dir, "en/blog/omoiyari-considerate-compassion.html", blog_omoiyari_en_view
      render export_dir, "en/blog/jiko-sekinin-personal-responsibility.html", blog_jiko_sekinin_en_view
      render export_dir, "en/blog/kuzushi-controlled-imbalance.html", blog_kuzushi_en_view

      Success(root)
    end

    private

    def render(export_dir, path, view, **input)
      base_context = Site::Container["view.context"]
      processed_path = path.sub(%r{(?:^|/)index.html$}, "")
      context = base_context.new(current_path: processed_path)

      export.(export_dir, path, view.(context: context, **input))
    end
  end
end

require "uri"
require "json"
require "dry/core/constants"
require "dry/view/context"
require "forwardable"
require "site/import"

module Site
  module View
    class Context < Dry::View::Context
      extend Forwardable

      include Dry::Core::Constants

      include Import["assets", "settings"]

      def_delegators :settings, :site_name, :site_author, :site_url

      attr_accessor :current_path
      attr_accessor :seo_description, :seo_keywords

      def initialize(current_path: nil, render_env: nil, **deps)
        super(render_env: render_env)

        @current_path = current_path
        @page_title = deps[:page_title]
        @_assets = deps[:assets]
        @_settings = deps[:settings]
      end

      def for_render_env(render_env)
        self.class.new(
          current_path: @current_path,
          render_env: render_env,
          assets: @_assets,
          settings: @_settings,
          page_title: @page_title
        )
      end

      def initialize_copy(source)
        super
        @current_path = source.instance_variable_get(:@current_path)
        @page_title = source.instance_variable_get(:@page_title)
        @_assets = source.instance_variable_get(:@_assets)
        @_settings = source.instance_variable_get(:@_settings)
      end

      def assets
        @_assets || super
      end

      def settings
        @_settings || super
      end

      def page_title(new_title = Undefined)
        if new_title == Undefined
          title = @page_title || default_title_for_path(current_path)
          return site_name if title.nil? || title.to_s.strip.empty?

          title_str = title.to_s
          site_name_str = site_name.to_s

          return title_str if title_str.downcase.include?(site_name_str.downcase)

          [title_str, site_name_str].join(" | ")
        else
          @page_title = new_title
        end
      end

      def default_title_for_path(path)
        case path
        when "index.html", "", nil
          "Aikido Polska | Sesshinkan Dojo Gdynia | POA - Treningi Aikido"
        when "en", "en/"
          "Polish Aikido Organization | Sesshinkan Dojo Gdynia - Aikido Training"
        when "kontakt.html"
          "Kontakt | Aikido Gdynia | Sesshinkan Dojo - Treningi Aikido"
        when "aikido/czym_jest.html"
          "Czym jest Aikido? | POA - Aikido Polska - Zasady i Filozofia"
        when "aikido/historia.html"
          "Historia Aikido | Od O-Sensei do wspolczesnosci | POA"
        when "aikido/korzysci.html"
          "Korzysci z Aikido | Zdrowie, Samoobrona, Rozwoj | POA"
        when "aikido/dla_poczatkujacych.html"
          "Aikido dla Poczatkujacych | Pierwszy Trening | Sesshinkan Dojo"
        when "aikido/aiki_taiso.html"
          "Aiki Taiso | Cwiczenia i Rozgrzewka Aikido | POA"
        when "aikido/reishiki.html"
          "Reishiki | Etykieta Dojo Aikido | Sesshinkan Dojo"
        when "aikido/budo_zen.html"
          "Budo i Zen w Aikido | Mushin, Zanshin i Bushido | POA"
        when "aikido/ki_kokyu.html"
          "Ki i Kokyu w Aikido | Energia i Siła Oddechu | POA"
        when "slowniczek.html"
          "Slowniczek Aikido | Terminy Japonskie | POA"
        when "wymagania_egzaminacyjne/kyu.html"
          "Wymagania Kyu | Stopnie Poczatkujace Aikido | POA"
        when "wymagania_egzaminacyjne/dan.html"
          "Wymagania Dan | Czarne Pasy Aikido | POA"
        when "lineage.html"
          "Linia Przekazu Aikido | Ueshiba, Toyoda, Germanov | POA"
        when "biografie/o-sensei.html"
          "Morihei Ueshiba O-Sensei | Tworca Aikido | Biografia"
        when "biografie/kisshomaru.html"
          "Kisshomaru Ueshiba | Drugi Doshu Aikido | Biografia"
        when "biografie/moriteru.html"
          "Moriteru Ueshiba | Trzeci Doshu Aikido | Biografia"
        when "biografie/mitsuteru.html"
          "Mitsuteru Ueshiba | Waka Sensei | Przyszly Doshu"
        when "biografie/toyoda.html"
          "Fumio Toyoda Shihan | Kluczowa Postac POA | Biografia"
        when "biografie/germanov.html"
          "Edward Germanov Shihan | 7 Dan | Prezes BAA"
        when "biografie/ostrowski.html"
          "Jacek Ostrowski | Zalozyciel POA | Wspomnienie"
        when "biografie/szrajer.html"
          "Oskar Szrajer | 5 Dan | Lider POA Gdynia"
        when "wydarzenia/2026.html"
          "Wydarzenia Aikido 2026 | Seminaria i Szkolenia | POA"
        when "faq.html"
          "FAQ | Czesto Zadawane Pytania | Aikido POA"
        when "gdynia.html"
          "Aikido Gdynia | Sesshinkan Dojo | Treningi Trójmiasto"
        when "yudansha.html"
          "Yudansha | Czarne Pasy POA | Instruktorzy Aikido"
        when "en/contact.html"
          "Contact | Aikido Gdynia | Sesshinkan Dojo - Training Schedule"
        when "en/aikido/what_is.html"
          "What is Aikido? | POA - Polish Aikido Organization - Principles"
        when "en/aikido/history.html"
          "History of Aikido | From O-Sensei to Present | POA"
        when "en/aikido/benefits.html"
          "Benefits of Aikido | Health, Self-Defense, Development | POA"
        when "en/aikido/beginners.html"
          "Aikido for Beginners | First Class | Sesshinkan Dojo"
        when "en/aikido/aiki_taiso.html"
          "Aiki Taiso | Exercises and Warm-up | Aikido POA"
        when "en/aikido/reishiki.html"
          "Reishiki | Dojo Etiquette | Sesshinkan Dojo"
        when "en/aikido/budo_zen.html"
          "Budo and Zen in Aikido | Mushin, Zanshin, Bushido | POA"
        when "en/aikido/ki_kokyu.html"
          "Ki and Kokyu in Aikido | Energy and Breath Power | POA"
        when "en/glossary.html"
          "Aikido Glossary | Japanese Terms | POA"
        when "en/requirements/kyu.html"
          "Kyu Requirements | Beginner Ranks Aikido | POA"
        when "en/requirements/dan.html"
          "Dan Requirements | Black Belt Aikido | POA"
        when "en/lineage.html"
          "Aikido Lineage | Ueshiba, Toyoda, Germanov | POA"
        when "en/biographies/o-sensei.html"
          "Morihei Ueshiba O-Sensei | Founder of Aikido | Biography"
        when "en/biographies/kisshomaru.html"
          "Kisshomaru Ueshiba | Second Doshu Aikido | Biography"
        when "en/biographies/moriteru.html"
          "Moriteru Ueshiba | Third Doshu Aikido | Biography"
        when "en/biographies/mitsuteru.html"
          "Mitsuteru Ueshiba | Waka Sensei | Future Doshu"
        when "en/biographies/toyoda.html"
          "Fumio Toyoda Shihan | Key Figure POA | Biography"
        when "en/biographies/germanov.html"
          "Edward Germanov Shihan | 7th Dan | BAA President"
        when "en/biographies/ostrowski.html"
          "Jacek Ostrowski | POA Founder | Memorial"
        when "en/biographies/szrajer.html"
          "Oskar Szrajer | 5th Dan | POA Head Gdynia"
        when "en/events/2026.html"
          "Aikido Events 2026 | Seminars and Workshops | POA"
        when "en/faq.html"
          "FAQ | Frequently Asked Questions | Aikido POA"
        when "en/gdynia.html"
          "Aikido Gdynia | Sesshinkan Dojo | Tri-City Training"
        when "en/yudansha.html"
          "Yudansha | POA Black Belts | Aikido Instructors"
        when "blog.html"
          "Blog | Polska Organizacja Aikido"
        when /\Ablog-(\d+)\.html\z/
          "Blog — strona #{$1} | Polska Organizacja Aikido"
        when "blog/bushido-droga-wojownika.html"
          "Bushido — droga wojownika w praktyce dojo | Blog"
        when "blog/kaizen-ciagle-doskonalenie.html"
          "Kaizen — ciągłe doskonalenie w Aikido | Blog"
        when "blog/gaman-wytrwalosc.html"
          "Gaman — wytrwałość i opanowanie na macie | Blog"
        when "blog/kintsugi-zlota-naprawa.html"
          "Kintsugi — złota naprawa i odporność psychiczna | Blog"
        when "blog/wabi-sabi-piekno-niedoskonalosci.html"
          "Wabi-sabi — piękno niedoskonałości w treningu | Blog"
        when "blog/mushin-umysl-bez-umyslu.html"
          "Mushin — umysł bez umysłu w Aikido | Blog"
        when "blog/sesshin-gleboka-praktyka.html"
          "Sesshin — głęboka praktyka i tożsamość Sesshinkan Dojo | Blog"
        when "blog/zenshin-pelne-zaangazowanie.html"
          "Zenshin — pełne zaangażowanie w każdym ruchu | Blog"
        when "blog/zanshin-czujnosc-po-technice.html"
          "Zanshin — czujność po technice i domknięcie działania | Blog"
        when "blog/enso-krag-obecnosci.html"
          "Ensō — krąg obecności i trening decyzji | Blog"
        when "blog/hyoshi-rytm-timing-jednosci-ruchu.html"
          "Hyōshi — rytm i timing jedności w Aikido | Blog"
        when "blog/fudoshin-niewzruszony-umysl.html"
          "Fudōshin — niewzruszony umysł i stabilność pod presją | Blog"
        when "blog/shoshin-umysl-poczatkujacego.html"
          "Shoshin — umysł początkującego i pokora w rozwoju | Blog"
        when "blog/shuhari-etapy-dojrzewania-w-treningu.html"
          "Shuhari — etapy dojrzewania w treningu i droga do swobody | Blog"
        when "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html"
          "Hansei — uczciwa autorefleksja bez wymówek i korekta ego | Blog"
        when "blog/aiki-harmonia-w-dzialaniu.html"
          "Aiki — harmonia w działaniu, nie w deklaracji | Blog"
        when "blog/misogi-oczyszczenie-przez-praktyke.html"
          "Misogi — oczyszczenie przez praktykę, nie przez pozę | Blog"
        when "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html"
          "Ichi-go ichi-e — każde spotkanie zdarza się tylko raz | Blog"
        when "blog/jeden-nauczyciel-jeden-przekaz.html"
          "Jeden nauczyciel, jeden przekaz — porządek nauki w dojo i na seminarium | Blog"
        when "blog/styl-aikido-fumio-toyody-technika-i-zen.html"
          "Styl Aikido Fumio Toyody — technika i Zen jako jeden system | Blog"
        when "blog/linia-toyoda-germanov-jak-cwiczymy.html"
          "Linia Toyoda–Germanov — jak ćwiczymy i czym wyróżnia się nasza szkoła | Blog"
        when "blog/omoiyari-uwazna-troska.html"
          "Omoiyari — uważna troska i odpowiedzialny partnering | Blog"
        when "blog/jiko-sekinin-odpowiedzialnosc-osobista.html"
          "Jiko sekinin — odpowiedzialność osobista w dojo | Blog"
        when "blog/kuzushi-kontrolowana-nierownowaga.html"
          "Kuzushi — kontrolowana nierównowaga i prowadzenie techniki | Blog"
        when "en/blog.html"
          "Blog | Polish Aikido Organization"
        when /\Aen\/blog-(\d+)\.html\z/
          "Blog — page #{$1} | Polish Aikido Organization"
        when "en/blog/bushido-way-of-the-warrior.html"
          "Bushido — the warrior's way in dojo practice | Blog"
        when "en/blog/kaizen-continuous-improvement.html"
          "Kaizen — continuous improvement in Aikido training | Blog"
        when "en/blog/gaman-endurance-and-composure.html"
          "Gaman — endurance and composure on the mat | Blog"
        when "en/blog/kintsugi-golden-repair.html"
          "Kintsugi — golden repair and resilient mindset | Blog"
        when "en/blog/wabi-sabi-beauty-of-imperfection.html"
          "Wabi-sabi — beauty of imperfection in practice | Blog"
        when "en/blog/mushin-no-mind.html"
          "Mushin — no-mind state in Aikido practice | Blog"
        when "en/blog/sesshin-deep-practice.html"
          "Sesshin — deep practice and Sesshinkan Dojo identity | Blog"
        when "en/blog/zenshin-full-commitment.html"
          "Zenshin — full commitment in every movement | Blog"
        when "en/blog/zanshin-awareness-after-execution.html"
          "Zanshin — awareness after execution and process closure | Blog"
        when "en/blog/enso-circle-of-presence.html"
          "Ensō — circle of presence and decision training | Blog"
        when "en/blog/hyoshi-timing-reveals-unity-of-movement.html"
          "Hyōshi — rhythm and timing of unity in Aikido | Blog"
        when "en/blog/fudoshin-immovable-mind.html"
          "Fudōshin — immovable mind and stability under pressure | Blog"
        when "en/blog/shoshin-beginners-mind.html"
          "Shoshin — beginner's mind and humility in growth | Blog"
        when "en/blog/shuhari-stages-of-maturation-in-training.html"
          "Shuhari — stages of maturation in training and the path to freedom | Blog"
        when "en/blog/hansei-honest-self-reflection-without-excuses.html"
          "Hansei — honest self-reflection without excuses and ego defense | Blog"
        when "en/blog/aiki-harmony-in-action.html"
          "Aiki — harmony in action, not in slogans | Blog"
        when "en/blog/misogi-purification-through-practice.html"
          "Misogi — purification through practice, not posture | Blog"
        when "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html"
          "Ichi-go ichi-e — every encounter happens only once | Blog"
        when "en/blog/one-teacher-one-transmission.html"
          "One teacher, one transmission — order in dojo and seminar learning | Blog"
        when "en/blog/toyoda-aikido-style-technique-and-zen.html"
          "Fumio Toyoda’s Aikido style — technique and Zen as one system | Blog"
        when "en/blog/toyoda-germanov-lineage-how-we-train.html"
          "Toyoda–Germanov lineage — how we train and what sets our school apart | Blog"
        when "en/blog/omoiyari-considerate-compassion.html"
          "Omoiyari — considerate compassion in partner work | Blog"
        when "en/blog/jiko-sekinin-personal-responsibility.html"
          "Jiko sekinin — personal responsibility in the dojo | Blog"
        when "en/blog/kuzushi-controlled-imbalance.html"
          "Kuzushi — controlled imbalance and technical guidance | Blog"
        else
          site_name
        end
      end

      def page_description(path_or_new_description = Undefined)
        if path_or_new_description == Undefined
          @seo_description || @page_description || default_description_for_path(current_path)
        elsif path_or_new_description.is_a?(String)
          @seo_description || @page_description || default_description_for_path(path_or_new_description)
        else
          @page_description = path_or_new_description
        end
      end

      def page_keywords(path_or_new_keywords = Undefined)
        if path_or_new_keywords == Undefined
          @seo_keywords || @page_keywords || default_keywords_for_path(current_path)
        elsif path_or_new_keywords.is_a?(String)
          @seo_keywords || @page_keywords || default_keywords_for_path(path_or_new_keywords)
        else
          @page_keywords = path_or_new_keywords
        end
      end

      def default_description_for_path(path)
        case path
        when "index.html", "", nil
          "Polska Organizacja Aikido w linii Shihan Fumio Toyody. Sesshinkan Dojo Gdynia - treningi Aikido w Trójmieście. Nowoczesne podejście do tradycyjnej sztuki walki."
        when "en", "en/"
          "Polish Aikido Organization following Shihan Fumio Toyoda's lineage. Sesshinkan Dojo Gdynia - Aikido training in Tri-City area. Modern approach to traditional martial art."
        when "kontakt.html"
          "Kontakt do Polskiej Organizacji Aikido (POA) i Sesshinkan Dojo Gdynia. Adres, telefon, e-mail, plan zajec i dane organizacji."
        when "aikido/czym_jest.html"
          "Czym jest Aikido - japonska sztuka walki oparta na harmonii, dzwigniach i rzutach. Zasady, filozofia i rozwoj osobisty."
        when "aikido/historia.html"
          "Historia Aikido od O-Sensei Morihei Ueshiby do wspolczesnosci. Rozwoj sztuki walki i jej rozprzestrzenienie."
        when "aikido/korzysci.html"
          "Korzysci z treningu Aikido: sprawnosc, koncentracja, redukcja stresu, samoobrona i rozwoj osobisty."
        when "aikido/dla_poczatkujacych.html"
          "Aikido dla poczatkujacych: jak wygladaja zajecia, podstawowe techniki, etykieta dojo i wskazowki na pierwszy trening."
        when "aikido/aiki_taiso.html"
          "Aiki Taiso - cwiczenia i rozgrzewka Aikido. Ruch, koordynacja i przygotowanie ciala do treningu."
        when "aikido/reishiki.html"
          "Reishiki - etykieta dojo Aikido: uklony, zachowanie, szacunek i tradycyjne zasady."
        when "aikido/budo_zen.html"
          "Budo i Zen w Aikido: Mushin, Zanshin, Fudoshin oraz cnoty wojownika. Filozofia i etyka praktyki dojo."
        when "aikido/ki_kokyu.html"
          "Ki i Kokyu w Aikido: energia życiowa, siła oddechu i praca z centrum. Poznaj pojęcia Ki, Kokyu-ryoku oraz praktykę oddechu."
        when "slowniczek.html"
          "Slowniczek terminow Aikido z tlumaczeniami japonskich nazw technik i pojec."
        when "wymagania_egzaminacyjne/kyu.html"
          "Wymagania egzaminacyjne Aikido na stopnie Kyu od 6 kyu do 1 kyu. Lista technik i zasad."
        when "wymagania_egzaminacyjne/dan.html"
          "Wymagania egzaminacyjne Aikido na stopnie Dan od Shodan wzwyz. Techniki i kryteria."
        when "lineage.html"
          "Linia przekazu Aikido od O-Sensei przez rodzine Ueshiba, Shihana Toyode i Germanova do POA."
        when "biografie/o-sensei.html"
          "Morihei Ueshiba O-Sensei - tworca Aikido. Zyciorys i idea sztuki opartej na harmonii."
        when "biografie/kisshomaru.html"
          "Kisshomaru Ueshiba - drugi Doshu Aikido. Rola w rozwoju i upowszechnieniu Aikido."
        when "biografie/moriteru.html"
          "Moriteru Ueshiba - trzeci Doshu Aikido. Przywodztwo Aikikai i wspolczesne Aikido."
        when "biografie/mitsuteru.html"
          "Mitsuteru Ueshiba - Waka Sensei, przyszly czwarty Doshu. Kontynuacja linii Ueshiba."
        when "biografie/toyoda.html"
          "Shihan Fumio Toyoda - wybitny nauczyciel Aikido i kluczowa postac linii POA."
        when "biografie/germanov.html"
          "Shihan Edward Germanov - 7 dan, prezes BAA i Tendokan. Rozwoj Aikido w Europie."
        when "biografie/ostrowski.html"
          "Sensei Jacek Ostrowski - zalozyciel Polskiej Organizacji Aikido. Wspomnienie nauczyciela."
        when "biografie/szrajer.html"
          "Sensei Oskar Szrajer - 5 dan, obecny lider POA i instruktor w Gdyni."
        when "wydarzenia/2026.html"
          "Wydarzenia Aikido 2026: seminaria, szkolenia, egzaminy i terminy spotkan POA."
        when "en/contact.html"
          "Contact Polish Aikido Organization and Sesshinkan Dojo Gdynia. Address, phone, email, training schedule, and organization details."
        when "en/aikido/what_is.html"
          "Aikido is a Japanese martial art based on harmony, locks, throws, and strikes. Learn about the Four Fundamental Principles, Ki energy, and the path of self-improvement through Aikido training."
        when "en/aikido/history.html"
          "History of Aikido from O-Sensei Morihei Ueshiba to modern times. Learn about the development of this Japanese martial art and its spread worldwide."
        when "en/aikido/benefits.html"
          "Benefits of Aikido training: physical fitness, mental focus, stress reduction, self-defense skills, and personal development through martial arts practice."
        when "en/aikido/beginners.html"
          "Complete guide for Aikido beginners: what to expect, how to prepare, training structure, basic techniques, and etiquette for your first classes."
        when "en/aikido/aiki_taiso.html"
          "Aiki Taiso - basic Aikido exercises and warm-up movements. Learn fundamental exercises that prepare body and mind for Aikido practice."
        when "en/aikido/reishiki.html"
          "Reishiki - Aikido dojo etiquette and ceremonial practices. Essential guide to respect, bowing, behavior, and traditional customs in Aikido training."
        when "en/aikido/budo_zen.html"
          "Budo and Zen in Aikido: Mushin, Zanshin, Fudoshin and the seven samurai virtues. Philosophy and ethics of dojo practice."
        when "en/aikido/ki_kokyu.html"
          "Ki and Kokyu in Aikido: life energy, breath power, and working from the center. Learn about Ki, Kokyu-ryoku, and breath training."
        when "en/glossary.html"
          "Complete Aikido glossary with Japanese terms, techniques, ranks, and philosophical concepts. Essential reference for practitioners."
        when "en/requirements/kyu.html"
          "Aikido Kyu rank examination requirements from 6th Kyu to 1st Kyu. Detailed list of techniques and knowledge required for colored belt tests."
        when "en/requirements/dan.html"
          "Aikido Dan rank examination requirements from Shodan to Yondan. Black belt techniques, principles, and mastery expectations for advanced practitioners."
        when "en/biographies/o-sensei.html"
          "Morihei Ueshiba O-Sensei - founder of Aikido. Biography of the master who created this martial art based on harmony and spiritual principles."
        when "en/biographies/kisshomaru.html"
          "Kisshomaru Ueshiba - second Doshu and son of O-Sensei. His role in spreading Aikido worldwide and systematizing the art."
        when "en/biographies/moriteru.html"
          "Moriteru Ueshiba - third and current Doshu of Aikido. Leading the international Aikido community and preserving O-Sensei's legacy."
        when "en/biographies/mitsuteru.html"
          "Mitsuteru Ueshiba - Waka Sensei and future fourth Doshu. Grandson of the current Doshu, continuing the Ueshiba family lineage."
        when "en/biographies/toyoda.html"
          "Shihan Fumio Toyoda - influential Aikido master who brought the art to America. Founder of AAA and our lineage's key teacher."
        when "en/biographies/germanov.html"
          "Shihan Edward Germanov - 7th dan, President of Baltic Aikido Association and Tendokan. Key figure in European Aikido development."
        when "en/biographies/ostrowski.html"
          "Sensei Jacek Ostrowski - founder of Polish Aikido Organization (POA). Memorial to a dedicated teacher who shaped Polish Aikido."
        when "en/biographies/szrajer.html"
          "Sensei Oskar Szrajer - 5th dan, current head of Polish Aikido Organization. Leading POA's development and training in Gdynia."
        when "en/lineage.html"
          "Aikido lineage from O-Sensei Morihei Ueshiba through the Ueshiba family, Shihan Toyoda, Shihan Germanov to Polish Aikido Organization."
        when "en/events/2026.html"
          "Aikido events and training seminars in 2026. Schedule of workshops, examinations, and special training sessions organized by POA."
        when "yudansha.html"
          "Lista 24 czarnych pasów (yudansha) Polskiej Organizacji Aikido - instruktorzy z rangą od Shodan (1 Dan) do Godan (5 Dan). Wszyscy wyegzaminowani w linii Shihan Fumio Toyoda."
        when "en/yudansha.html"
          "List of 24 black belts (yudansha) from Polish Aikido Organization - instructors ranked from Shodan (1st Dan) to Godan (5th Dan). All examined in Shihan Fumio Toyoda's lineage."
        when "blog.html"
          "Blog POA: relacje ze staży, komunikaty dojo, zapowiedzi wydarzeń i informacje dla ćwiczących Aikido."
        when /\Ablog-(\d+)\.html\z/
          "Blog POA — starsze wpisy (strona #{$1}): archiwalne artykuły, relacje i komentarze treningowe."
        when "blog/bushido-droga-wojownika.html"
          "Bushido w praktyce Aikido: dyscyplina, odpowiedzialność i etyka pracy w dojo, które budują trwałe umiejętności."
        when "blog/kaizen-ciagle-doskonalenie.html"
          "Kaizen w treningu Aikido: małe, konsekwentne kroki, które przekładają się na realny postęp techniczny i mentalny."
        when "blog/gaman-wytrwalosc.html"
          "Gaman jako fundament praktyki: wytrwałość, opanowanie i jakość decyzji pod presją na macie i poza nią."
        when "blog/kintsugi-zlota-naprawa.html"
          "Kintsugi jako metafora rozwoju aikidoki: jak błędy, korekta i konsekwencja wzmacniają technikę oraz charakter."
        when "blog/wabi-sabi-piekno-niedoskonalosci.html"
          "Wabi-sabi w Aikido: akceptacja niedoskonałości, praca nad detalem i dojrzewanie techniki przez regularny trening."
        when "blog/mushin-umysl-bez-umyslu.html"
          "Mushin w praktyce: jak budować swobodną, nieusztywnioną reakcję i utrzymywać klarowność działania w technice."
        when "blog/sesshin-gleboka-praktyka.html"
          "Sesshin jako głęboka praktyka Aikido: koncentracja, dyscyplina i standard pracy, który definiuje Sesshinkan Dojo."
        when "blog/zenshin-pelne-zaangazowanie.html"
          "Zenshin, czyli pełne zaangażowanie ciała i umysłu w ruchu, kontakt z partnerem i finalizację techniki."
        when "blog/zanshin-czujnosc-po-technice.html"
          "Zanshin jako pozostająca czujność po wykonaniu techniki: jak domykać działanie i utrzymywać jakość pod presją."
        when "blog/enso-krag-obecnosci.html"
          "Ensō w praktyce Aikido i zen: jeden ruch, który odsłania jakość obecności, decyzji i domknięcia działania."
        when "blog/hyoshi-rytm-timing-jednosci-ruchu.html"
          "Hyōshi w Aikido i budō: jak timing ujawnia jedność decyzji, oddechu i ruchu oraz dlaczego spóźnienie niszczy technikę."
        when "blog/fudoshin-niewzruszony-umysl.html"
          "Fudōshin w Aikido i budō: niewzruszony umysł jako praktyczna stabilność decyzji, oddechu i postawy pod presją."
        when "blog/shoshin-umysl-poczatkujacego.html"
          "Shoshin w Aikido i budō: jak umysł początkującego chroni przed rutyną, pychą i techniczną stagnacją."
        when "blog/shuhari-etapy-dojrzewania-w-treningu.html"
          "Shuhari w Aikido i budō: jak wiernie przepracowana forma dojrzewa w zrozumienie i swobodę, zamiast rozpadać się w chaos lub ego."
        when "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html"
          "Hansei w Aikido i budō: jak uczciwa autorefleksja bez wymówek pozwala zobaczyć własny błąd, przyjąć korektę i naprawdę dojrzewać w treningu."
        when "blog/aiki-harmonia-w-dzialaniu.html"
          "Aiki w Aikido: jak przejąć timing, dystans i balans ataku bez zderzania siły z siłą oraz dlaczego ta zasada zaczyna się jeszcze przed techniką."
        when "blog/misogi-oczyszczenie-przez-praktyke.html"
          "Misogi w Aikido i budō: jak praktyka oczyszczania oddechu, uwagi i intencji wzmacnia technikę w stylu Toyody oraz pozostaje żywa w linii przekazu."
        when "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html"
          "Ichi-go ichi-e w Aikido i budō: dlaczego każde spotkanie, trening i korekta zdarzają się tylko raz i wymagają pełnej obecności zamiast rutyny."
        when "blog/jeden-nauczyciel-jeden-przekaz.html"
          "Jeden nauczyciel i jeden spójny przekaz chronią ucznia przed chaosem, a starszy uczeń najlepiej wspiera naukę jako dobry uke."
        when "blog/styl-aikido-fumio-toyody-technika-i-zen.html"
          "Czym wyróżnia się styl Aikido Fumio Toyody? Poznaj połączenie precyzji technicznej, oddechu i dyscypliny Zen w jednym systemie treningowym."
        when "blog/linia-toyoda-germanov-jak-cwiczymy.html"
          "Linia Toyoda–Germanov w praktyce: precyzja techniczna, dyscyplina wewnętrzna i odpowiedzialny przekaz instruktorski na tle innych nurtów Aikido."
        when "blog/omoiyari-uwazna-troska.html"
          "Omoiyari w dojo: uważna troska o partnera, bezpieczeństwo treningu i wysoka kultura współpracy na macie."
        when "blog/jiko-sekinin-odpowiedzialnosc-osobista.html"
          "Jiko sekinin w Aikido: odpowiedzialność za własny rozwój, przygotowanie, higienę techniki i postawę na treningu."
        when "blog/kuzushi-kontrolowana-nierownowaga.html"
          "Kuzushi od podstaw do zastosowania: kontrolowana nierównowaga, timing i kierunek, które otwierają skuteczną technikę."
        when "en/blog.html"
          "POA blog: seminar recaps, dojo updates, event announcements, and practical notes for Aikido practitioners."
        when /\Aen\/blog-(\d+)\.html\z/
          "POA blog — older posts (page #{$1}): archived articles, recaps, and practical dojo notes."
        when "en/blog/bushido-way-of-the-warrior.html"
          "Bushido in practical Aikido training: discipline, accountability, and dojo ethics that shape durable martial skills."
        when "en/blog/kaizen-continuous-improvement.html"
          "Kaizen applied to Aikido: steady incremental improvement that compounds into reliable technical and mental progress."
        when "en/blog/gaman-endurance-and-composure.html"
          "Gaman as a training principle: endurance, composure, and quality decision-making under pressure on the mat."
        when "en/blog/kintsugi-golden-repair.html"
          "Kintsugi as a growth model in Aikido: learning from mistakes, repairing structure, and building resilient performance."
        when "en/blog/wabi-sabi-beauty-of-imperfection.html"
          "Wabi-sabi in Aikido practice: accepting imperfection while refining movement, timing, and technical clarity."
        when "en/blog/mushin-no-mind.html"
          "Mushin in partner work: developing clear, unforced responses and preserving calm precision in motion."
        when "en/blog/sesshin-deep-practice.html"
          "Sesshin as deep Aikido practice: concentration, discipline, and the training standard that defines Sesshinkan Dojo."
        when "en/blog/zenshin-full-commitment.html"
          "Zenshin means full commitment: body-mind unity, intent continuity, and complete execution of technique."
        when "en/blog/zanshin-awareness-after-execution.html"
          "Zanshin as remaining awareness after technique: how to close action loops and preserve quality under pressure."
        when "en/blog/enso-circle-of-presence.html"
          "Ensō in Aikido and Zen practice: one stroke that reveals presence, decision quality, and clean closure."
        when "en/blog/hyoshi-timing-reveals-unity-of-movement.html"
          "Hyōshi in Aikido and budō: how timing reveals unity of decision, breath, and movement—and why delay breaks technique."
        when "en/blog/fudoshin-immovable-mind.html"
          "Fudōshin in Aikido and budō: immovable mind as practical stability of decision, breath, and posture under pressure."
        when "en/blog/shoshin-beginners-mind.html"
          "Shoshin in Aikido and budō: how beginner's mind protects training from routine, ego, and technical stagnation."
        when "en/blog/shuhari-stages-of-maturation-in-training.html"
          "Shuhari in Aikido and budō: how faithful form matures into understanding and freedom without collapsing into chaos or ego."
        when "en/blog/hansei-honest-self-reflection-without-excuses.html"
          "Hansei in Aikido and budō: how honest self-reflection without excuses helps practitioners see error clearly, accept correction, and mature in training."
        when "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html"
          "Ichi-go ichi-e in Aikido and budō: why every encounter, training session, and correction happens only once and deserves full presence instead of routine."
        when "en/blog/misogi-purification-through-practice.html"
          "Misogi in Aikido and budō: how clearing breath, attention, and intention strengthens technique in Toyoda’s style and remains alive in the transmission line."
        when "en/blog/one-teacher-one-transmission.html"
          "One teacher and one coherent transmission protect students from confusion, and senior students support learning best by being good uke."
        when "en/blog/toyoda-aikido-style-technique-and-zen.html"
          "What defines Fumio Toyoda’s Aikido style? Discover how technical precision, breath work, and Zen discipline form one coherent training system."
        when "en/blog/toyoda-germanov-lineage-how-we-train.html"
          "Toyoda–Germanov lineage in practice: technical precision, inner discipline, and responsible instruction compared with other Aikido streams."
        when "en/blog/omoiyari-considerate-compassion.html"
          "Omoiyari in the dojo: considerate compassion, partner safety, and responsible intensity in everyday training."
        when "en/blog/jiko-sekinin-personal-responsibility.html"
          "Jiko sekinin in Aikido: personal responsibility for preparation, attitude, and the quality of each repetition."
        when "en/blog/kuzushi-controlled-imbalance.html"
          "Kuzushi explained through practice: controlled imbalance, timing, and direction to unlock effective technique."
        else
          page_title
        end
      end

      def default_keywords_for_path(path)
        case path
        when "index.html", "", nil
          "Aikido Polska, Aikido Gdynia, Aikido Trójmiasto, POA, Polska Organizacja Aikido, Sesshinkan Dojo, Toyoda, Germanov, Oskar Szrajer, sztuki walki Gdynia, samoobrona Gdynia, treningi Aikido, dojo Gdynia"
        when "en", "en/"
          "Aikido Poland, Aikido Gdynia, Aikido Polish, POA, Polish Aikido Organization, Sesshinkan Dojo, Toyoda, Germanov, Oskar Szrajer, martial arts Gdynia, self-defense training, Aikido classes, dojo Gdynia"
        when "kontakt.html"
          "kontakt aikido, POA, Sesshinkan Dojo Gdynia, treningi Aikido Gdynia, telefon, adres, plan zajec"
        when "aikido/czym_jest.html"
          "czym jest aikido, aikido, sztuka walki, zasady aikido, filozofia aikido, aikikai"
        when "aikido/historia.html"
          "historia aikido, Morihei Ueshiba, O-Sensei, rozwoj aikido, japonskie sztuki walki"
        when "aikido/korzysci.html"
          "korzysci aikido, samoobrona, rozwoj osobisty, sprawnosc, trening aikido"
        when "aikido/dla_poczatkujacych.html"
          "aikido dla poczatkujacych, pierwszy trening, podstawy aikido, dojo, etykieta"
        when "aikido/aiki_taiso.html"
          "aiki taiso, cwiczenia aikido, rozgrzewka, przygotowanie do treningu, koordynacja"
        when "aikido/reishiki.html"
          "reishiki, etykieta dojo, uklony, zasady dojo, aikido"
        when "aikido/budo_zen.html"
          "budo, zen, mushin, zanshin, fudoshin, bushido, cnoty samuraja, filozofia aikido"
        when "aikido/ki_kokyu.html"
          "ki, kokyu, kokyu-ryoku, energia życiowa, oddech w aikido, hara, seika tanden, ki no nagare"
        when "slowniczek.html"
          "slowniczek aikido, terminy japonskie, nazwy technik, aikido"
        when "wymagania_egzaminacyjne/kyu.html"
          "wymagania kyu, stopnie kyu, egzamin aikido, pasy aikido"
        when "wymagania_egzaminacyjne/dan.html"
          "wymagania dan, shodan, nidan, stopnie mistrzowskie, egzamin aikido"
        when "lineage.html"
          "linia przekazu aikido, ueshiba, toyoda, germanov, poa, tradycja"
        when "biografie/o-sensei.html"
          "morihei ueshiba, o-sensei, tworca aikido, biografia"
        when "biografie/kisshomaru.html"
          "kisshomaru ueshiba, doshu, aikido historia, biografia"
        when "biografie/moriteru.html"
          "moriteru ueshiba, doshu, aikido aikikai, biografia"
        when "biografie/mitsuteru.html"
          "mitsuteru ueshiba, waka sensei, doshu, biografia"
        when "biografie/toyoda.html"
          "fumio toyoda, shihan toyoda, aikido america, biografia"
        when "biografie/germanov.html"
          "edward germanov, shihan germanov, 7 dan, baa, biografia"
        when "biografie/ostrowski.html"
          "jacek ostrowski, poa, zalozyciel, biografia"
        when "biografie/szrajer.html"
          "oskar szrajer, poa, 5 dan, instruktor, biografia"
        when "wydarzenia/2026.html"
          "wydarzenia aikido 2026, seminaria, szkolenia, poa"
        when "en/contact.html"
          "contact Polish Aikido Organization, Sesshinkan Dojo Gdynia, Aikido contact, training schedule, phone"
        when "en/aikido/what_is.html"
          "What is Aikido, Aikido principles, Ki energy, Aiki, martial arts philosophy, Japanese martial arts, Aikido training, Four Fundamental Principles, Morihei Ueshiba"
        when "en/aikido/history.html"
          "Aikido history, Morihei Ueshiba, O-Sensei, martial arts history, Japanese budo, Aikido development, traditional martial arts"
        when "en/aikido/benefits.html"
          "Aikido benefits, martial arts training, self-defense, physical fitness, mental focus, stress relief, personal development, mind-body practice"
        when "en/aikido/beginners.html"
          "Aikido for beginners, first Aikido class, martial arts beginners, Aikido basics, dojo etiquette, starting Aikido, beginner guide"
        when "en/aikido/aiki_taiso.html"
          "Aiki Taiso, Aikido exercises, warm-up exercises, martial arts conditioning, body movement, Aikido preparation, basic training"
        when "en/aikido/reishiki.html"
          "Reishiki, dojo etiquette, Aikido customs, martial arts respect, Japanese etiquette, bowing, dojo behavior, training protocol"
        when "en/aikido/budo_zen.html"
          "budo, zen, mushin, zanshin, fudoshin, bushido virtues, samurai ethics, Aikido philosophy"
        when "en/aikido/ki_kokyu.html"
          "Ki, Kokyu, Kokyu-ryoku, life energy, breath power, Aikido breathing, hara, seika tanden"
        when "en/glossary.html"
          "Aikido glossary, Japanese terms, martial arts terminology, Aikido dictionary, techniques names, ranks system, Japanese martial arts"
        when "en/requirements/kyu.html"
          "Kyu ranks, Aikido belts, colored belts, examination requirements, Aikido grading, beginner ranks, martial arts progression"
        when "en/requirements/dan.html"
          "Dan ranks, black belt, Aikido black belt, Shodan, Nidan, Sandan, Yondan, advanced requirements, master level"
        when "en/biographies/o-sensei.html"
          "Morihei Ueshiba, O-Sensei, Aikido founder, martial arts master, Japanese budo, Aikido creator, spiritual martial arts"
        when "en/biographies/kisshomaru.html"
          "Kisshomaru Ueshiba, second Doshu, Aikido development, Ueshiba family, Aikido worldwide, martial arts leadership"
        when "en/biographies/moriteru.html"
          "Moriteru Ueshiba, third Doshu, current Doshu, Aikido leadership, Aikikai, international Aikido, modern Aikido"
        when "en/biographies/mitsuteru.html"
          "Mitsuteru Ueshiba, Waka Sensei, future Doshu, Ueshiba lineage, next generation, Aikido succession"
        when "en/biographies/toyoda.html"
          "Fumio Toyoda, Shihan Toyoda, Aikido America, AAA founder, influential teacher, Aikido lineage, martial arts pioneer"
        when "en/biographies/germanov.html"
          "Edward Germanov, Shihan Germanov, 7th dan, Baltic Aikido, Tendokan, European Aikido, BAA President"
        when "en/biographies/ostrowski.html"
          "Jacek Ostrowski, POA founder, Polish Aikido, Aikido memorial, dedicated teacher, martial arts legacy"
        when "en/biographies/szrajer.html"
          "Oskar Szrajer, 5th dan, POA head, Gdynia Aikido, current instructor, Sesshinkan Dojo, Polish teacher"
        when "en/lineage.html"
          "Aikido lineage, martial arts lineage, Ueshiba family, Toyoda lineage, Germanov lineage, POA lineage, traditional succession"
        when "en/events/2026.html"
          "Aikido events 2026, seminars, workshops, training schedule, martial arts events, POA calendar, Aikido gatherings"
        when "yudansha.html"
          "yudansha, czarne pasy POA, Aikido instruktorzy, Shodan, Nidan, Sandan, Yondan, Godan, Dan Aikido, instruktorzy Aikido Polska, stopnie mistrzowskie, Jacek Ostrowski, Oskar Szrajer, Wojciech Korwin-Piotrowski"
        when "en/yudansha.html"
          "yudansha, POA black belts, Aikido instructors, Shodan, Nidan, Sandan, Yondan, Godan, Dan ranks, Aikido instructors Poland, black belt instructors, Jacek Ostrowski, Oskar Szrajer, Wojciech Korwin-Piotrowski"
        when "blog.html"
          "blog aikido, poa blog, seminaria aikido, dojo komunikaty, sesshinkan gdynia"
        when /\Ablog-(\d+)\.html\z/
          "blog aikido archiwum, starsze wpisy poa, artykuly dojo, aikido gdynia"
        when "blog/bushido-droga-wojownika.html"
          "bushido aikido, droga wojownika, etyka dojo, dyscyplina treningowa, zasady budo"
        when "blog/kaizen-ciagle-doskonalenie.html"
          "kaizen aikido, ciagle doskonalenie, nawyki treningowe, postep techniczny, rozwoj dojo"
        when "blog/gaman-wytrwalosc.html"
          "gaman aikido, wytrwalosc, opanowanie, odpornosc psychiczna, trening pod presja"
        when "blog/kintsugi-zlota-naprawa.html"
          "kintsugi aikido, zlota naprawa, praca z bledem, odpornosc, rozwoj osobisty"
        when "blog/wabi-sabi-piekno-niedoskonalosci.html"
          "wabi sabi aikido, piekno niedoskonalosci, pokora w treningu, proces doskonalenia"
        when "blog/mushin-umysl-bez-umyslu.html"
          "mushin aikido, umysl bez umyslu, reakcja spontaniczna, skupienie, zen w ruchu"
        when "blog/sesshin-gleboka-praktyka.html"
          "sesshin aikido, gleboka praktyka, intensywny trening, sesshinkan dojo, dyscyplina i skupienie"
        when "blog/zenshin-pelne-zaangazowanie.html"
          "zenshin aikido, pelne zaangazowanie, intencja ruchu, koncentracja, jakosc techniki"
        when "blog/zanshin-czujnosc-po-technice.html"
          "zanshin aikido, pozostajaca czujnosc, domkniecie techniki, uwaga po ruchu, jakosc decyzji"
        when "blog/enso-krag-obecnosci.html"
          "enso aikido, enso zen, zen circle, krag zen, obecność w ruchu, decyzja pod presją"
        when "blog/hyoshi-rytm-timing-jednosci-ruchu.html"
          "hyoshi aikido, timing aikido, rytm ruchu, ma-ai kokyu zanshin, jedność ciała i umysłu, budo"
        when "blog/fudoshin-niewzruszony-umysl.html"
          "fudoshin aikido, niewzruszony umysl, stabilnosc pod presja, spokoj w dzialaniu, budo, zen"
        when "blog/shoshin-umysl-poczatkujacego.html"
          "shoshin aikido, umysl poczatkujacego, pokora w treningu, rozwoj bez pychy, podstawy aikido, zen"
        when "blog/shuhari-etapy-dojrzewania-w-treningu.html"
          "shuhari aikido, etapy uczenia, dojrzewanie w treningu, shu ha ri, forma i swoboda, budo, zen"
        when "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html"
          "hansei aikido, autorefleksja bez wymowek, uczciwa korekta, praca z bledem, rozwoj w dojo, budo, zen"
        when "blog/aiki-harmonia-w-dzialaniu.html"
          "aiki aikido, aiki w aikido, harmonia w dzialaniu, timing dystans balans, ma-ai kuzushi kokyu, prowadzenie ataku"
        when "blog/misogi-oczyszczenie-przez-praktyke.html"
          "misogi, misogi aikido, toyoda misogi, oczyszczenie w budo, zen i aikido, linia toyoda germanov"
        when "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html"
          "ichi go ichi e aikido, kazde spotkanie zdarza sie tylko raz, obecnosc w treningu, uwaga w dojo, seminaria aikido, budo, zen"
        when "blog/jeden-nauczyciel-jeden-przekaz.html"
          "jeden nauczyciel jeden przekaz, aikido nauczanie, metodyka dojo, seminarium aikido, uke, shuhari, przekaz szkoły"
        when "blog/styl-aikido-fumio-toyody-technika-i-zen.html"
          "styl aikido toyody, fumio toyoda, aikido zen, misogi, trening budo, linia toyoda"
        when "blog/linia-toyoda-germanov-jak-cwiczymy.html"
          "linia toyoda germanov, aikido germanov, metodyka aikido, budo praktyka, aikido szkoła"
        when "blog/omoiyari-uwazna-troska.html"
          "omoiyari aikido, uwazna troska, partnering, bezpieczenstwo na macie, kultura dojo"
        when "blog/jiko-sekinin-odpowiedzialnosc-osobista.html"
          "jiko sekinin aikido, odpowiedzialnosc osobista, samodyscyplina, etyka treningu"
        when "blog/kuzushi-kontrolowana-nierownowaga.html"
          "kuzushi aikido, kontrolowana nierownowaga, balans, timing, prowadzenie partnera"
        when "en/blog.html"
          "aikido blog, poa updates, dojo announcements, seminar recap, sesshinkan"
        when /\Aen\/blog-(\d+)\.html\z/
          "aikido blog archive, older posts, dojo articles, poa updates"
        when "en/blog/bushido-way-of-the-warrior.html"
          "bushido aikido, warrior way, dojo ethics, training discipline, budo principles"
        when "en/blog/kaizen-continuous-improvement.html"
          "kaizen aikido, continuous improvement, training habits, technical progression, dojo growth"
        when "en/blog/gaman-endurance-and-composure.html"
          "gaman aikido, endurance, composure, resilience, pressure training"
        when "en/blog/kintsugi-golden-repair.html"
          "kintsugi aikido, golden repair, learning from mistakes, resilience, mindset"
        when "en/blog/wabi-sabi-beauty-of-imperfection.html"
          "wabi sabi aikido, beauty of imperfection, humility, long-term training process"
        when "en/blog/mushin-no-mind.html"
          "mushin aikido, no mind, spontaneous response, calm focus, zen in movement"
        when "en/blog/sesshin-deep-practice.html"
          "sesshin aikido, deep practice, intensive training, sesshinkan dojo, discipline and focus"
        when "en/blog/zenshin-full-commitment.html"
          "zenshin aikido, full commitment, intent continuity, concentration, execution quality"
        when "en/blog/zanshin-awareness-after-execution.html"
          "zanshin aikido, remaining awareness, follow-through, post-execution control, decision quality"
        when "en/blog/enso-circle-of-presence.html"
          "enso aikido, enso zen, zen circle, presence in motion, decision under pressure, clean execution"
        when "en/blog/hyoshi-timing-reveals-unity-of-movement.html"
          "hyoshi aikido, aikido timing, rhythm in movement, ma-ai kokyu zanshin, body-mind unity, budo"
        when "en/blog/fudoshin-immovable-mind.html"
          "fudoshin aikido, immovable mind, stability under pressure, calm action, budo, zen"
        when "en/blog/shoshin-beginners-mind.html"
          "shoshin aikido, beginner's mind, humility in training, growth without ego, aikido fundamentals, zen"
        when "en/blog/shuhari-stages-of-maturation-in-training.html"
          "shuhari aikido, stages of learning, maturation in training, shu ha ri, form and freedom, budo, zen"
        when "en/blog/hansei-honest-self-reflection-without-excuses.html"
          "hansei aikido, honest self-reflection, training correction, working with error, dojo growth, budo, zen"
        when "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html"
          "ichi go ichi e aikido, every encounter happens only once, presence in training, dojo attention, aikido seminars, budo, zen"
        when "en/blog/misogi-purification-through-practice.html"
          "misogi, misogi aikido, toyoda misogi, purification in budo, zen and aikido, toyoda germanov lineage"
        when "en/blog/one-teacher-one-transmission.html"
          "one teacher one transmission, aikido teaching, dojo pedagogy, aikido seminar, uke, shuhari, school transmission"
        when "en/blog/toyoda-aikido-style-technique-and-zen.html"
          "toyoda aikido style, fumio toyoda, aikido zen, misogi, budo training, toyoda lineage"
        when "en/blog/toyoda-germanov-lineage-how-we-train.html"
          "toyoda germanov lineage, germanov aikido, aikido methodology, budo practice, aikido school"
        when "en/blog/omoiyari-considerate-compassion.html"
          "omoiyari aikido, considerate compassion, partner safety, cooperative training, dojo culture"
        when "en/blog/jiko-sekinin-personal-responsibility.html"
          "jiko sekinin aikido, personal responsibility, self-discipline, training ethics"
        when "en/blog/kuzushi-controlled-imbalance.html"
          "kuzushi aikido, controlled imbalance, timing, direction, partner guidance"
        else
          "Aikido, POA, Polska Organizacja Aikido, Polish Aikido Organization, Toyoda, Germanov"
        end
      end

      def default_description
        default_description_for_path(@current_path)
      end

      def default_keywords
        default_keywords_for_path(@current_path)
      end

      BLOG_POSTS_PER_PAGE = 10

      BLOG_POSTS_PL = [
        { date: "4 kwietnia 2026", title: "Misogi (禊) — oczyszczenie przez praktykę", url: "/blog/misogi-oczyszczenie-przez-praktyke.html", summary: "Dlaczego misogi w stylu Toyody porządkuje oddech, uwagę i intencję oraz pozostaje żywą praktyką w linii przekazu." },
        { date: "2 kwietnia 2026", title: "Aiki (合気) — harmonia w działaniu, nie w deklaracji", url: "/blog/aiki-harmonia-w-dzialaniu.html", summary: "Dlaczego Aiki w Aikido zaczyna się przed techniką i oznacza przejęcie timingu, dystansu oraz balansu bez siłowego zderzenia." },
        { date: "26 marca 2026", title: "Ichi-go ichi-e (一期一会) — każde spotkanie zdarza się tylko raz", url: "/blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html", summary: "Dlaczego każda chwila treningu, korekta i spotkanie z partnerem są niepowtarzalne i wymagają pełnej obecności zamiast rutyny." },
        { date: "26 marca 2026", title: "Hansei (反省) — uczciwa autorefleksja bez wymówek", url: "/blog/hansei-uczciwa-autorefleksja-bez-wymowek.html", summary: "Dlaczego bez uczciwego zobaczenia własnego błędu trening zamienia się w obronę ego zamiast realnej korekty." },
        { date: "18 marca 2026", title: "Jeden nauczyciel, jeden przekaz", url: "/blog/jeden-nauczyciel-jeden-przekaz.html", summary: "Dlaczego jeden spójny przekaz chroni naukę przed chaosem, a starszy uczeń najlepiej wspiera trening jako dobry uke." },
        { date: "18 marca 2026", title: "Shuhari (守破離) — etapy dojrzewania w treningu", url: "/blog/shuhari-etapy-dojrzewania-w-treningu.html", summary: "Jak wiernie przepracowana forma dojrzewa w zrozumienie i swobodę, zamiast rozpadać się w chaos lub ego." },
        { date: "15 marca 2026", title: "Shoshin (初心) — umysł początkującego", url: "/blog/shoshin-umysl-poczatkujacego.html", summary: "Dlaczego prawdziwy rozwój zaczyna się tam, gdzie doświadczenie nie zamienia się jeszcze w pychę i rutynę." },
        { date: "14 marca 2026", title: "Fudōshin (不動心) — niewzruszony umysł", url: "/blog/fudoshin-niewzruszony-umysl.html", summary: "Jak zachować stabilność decyzji, oddechu i postawy wtedy, gdy presja najbardziej chce rozbić technikę." },
        { date: "7 marca 2026", title: "Styl Aikido Fumio Toyody: technika i Zen jako jeden system", url: "/blog/styl-aikido-fumio-toyody-technika-i-zen.html", summary: "Jak w linii Toyody łączy się precyzję techniki, oddech i dyscyplinę Zen w jednej metodyce treningowej." },
        { date: "7 marca 2026", title: "Linia Toyoda–Germanov: jak ćwiczymy i czym wyróżnia się nasza szkoła", url: "/blog/linia-toyoda-germanov-jak-cwiczymy.html", summary: "Profil naszej praktyki: precyzja techniczna, praca wewnętrzna i odpowiedzialny przekaz instruktorski." },
        { date: "6 marca 2026", title: "Hyōshi (拍子) — rytm i timing jedności", url: "/blog/hyoshi-rytm-timing-jednosci-ruchu.html", summary: "Cięcie ruchu albo jego rozlanie natychmiast ujawnia jakość jedności ciała, oddechu i decyzji." },
        { date: "6 marca 2026", title: "Ensō (円相) — krąg obecności", url: "/blog/enso-krag-obecnosci.html", summary: "Jeden ruch pędzla, który bezlitośnie pokazuje jakość umysłu i decyzji pod presją." },
        { date: "25 lutego 2026", title: "Zanshin (残心) — czujność po technice", url: "/blog/zanshin-czujnosc-po-technice.html", summary: "Dlaczego najwięcej błędów pojawia się po ruchu i jak utrzymać uwagę do końca działania." },
        { date: "24 lutego 2026", title: "Sesshin (接心) — głęboka praktyka i skupienie", url: "/blog/sesshin-gleboka-praktyka.html", summary: "Dlaczego Sesshin to fundament naszej metody pracy i kluczowy element tożsamości Sesshinkan Dojo." },
        { date: "23 lutego 2026", title: "Bushido (武士道) — droga wojownika", url: "/blog/bushido-droga-wojownika.html", summary: "Kodeks samuraja i siedem cnót, które można stosować dziś: na macie, w pracy i w codziennych decyzjach." },
        { date: "23 lutego 2026", title: "Kaizen (改善) — ciągłe doskonalenie", url: "/blog/kaizen-ciagle-doskonalenie.html", summary: "Małe, codzienne kroki prowadzą do trwałego postępu i mocnych fundamentów techniki." },
        { date: "23 lutego 2026", title: "Gaman (我慢) — wytrwałość i opanowanie", url: "/blog/gaman-wytrwalosc.html", summary: "Sztuka znoszenia trudności z godnością, spokojem i dojrzałością." },
        { date: "23 lutego 2026", title: "Kintsugi (金継ぎ) — złota naprawa", url: "/blog/kintsugi-zlota-naprawa.html", summary: "Pęknięcia nie muszą być ukrywane — mogą stać się źródłem siły i nowego znaczenia." },
        { date: "23 lutego 2026", title: "Wabi-Sabi (侘寂) — piękno niedoskonałości", url: "/blog/wabi-sabi-piekno-niedoskonalosci.html", summary: "Akceptacja prostoty, przemijania i niedoskonałości jako części naturalnego rozwoju." },
        { date: "23 lutego 2026", title: "Mushin (無心) — umysł bez umysłu", url: "/blog/mushin-umysl-bez-umyslu.html", summary: "Stan pełnej obecności: bez napięcia, bez przywiązania, z jasnym działaniem." },
        { date: "23 lutego 2026", title: "Zenshin (前進) — pełne zaangażowanie", url: "/blog/zenshin-pelne-zaangazowanie.html", summary: "Konsekwentny ruch naprzód z całą uwagą i odpowiedzialnością za proces." },
        { date: "23 lutego 2026", title: "Omoiyari (思いやり) — uważna troska", url: "/blog/omoiyari-uwazna-troska.html", summary: "Empatia w praktyce: rozumienie potrzeb drugiej osoby zanim zostaną wypowiedziane." },
        { date: "23 lutego 2026", title: "Jiko Sekinin (自己責任) — odpowiedzialność osobista", url: "/blog/jiko-sekinin-odpowiedzialnosc-osobista.html", summary: "Branie odpowiedzialności za decyzje, błędy i konsekwencje bez szukania wymówek." },
        { date: "23 lutego 2026", title: "Kuzushi (崩し) — kontrolowana nierównowaga", url: "/blog/kuzushi-kontrolowana-nierownowaga.html", summary: "W Aikido i poza matą: jak świadomie zmieniać układ sił, by otworzyć przestrzeń na transformację." }
      ].freeze

      BLOG_POSTS_EN = [
        { date: "April 4, 2026", title: "Misogi (禊) — purification through practice", url: "/en/blog/misogi-purification-through-practice.html", summary: "Why misogi in Toyoda’s style orders breath, attention, and intention and remains a living practice in the transmission line." },
        { date: "April 2, 2026", title: "Aiki (合気) — harmony in action, not in slogans", url: "/en/blog/aiki-harmony-in-action.html", summary: "Why Aiki in Aikido begins before technique and means taking timing, distance, and balance without clashing force against force." },
        { date: "March 26, 2026", title: "Ichi-go ichi-e (一期一会) — every encounter happens only once", url: "/en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html", summary: "Why every training moment, correction, and encounter with a partner is unrepeatable and deserves full presence instead of routine." },
        { date: "March 26, 2026", title: "Hansei (反省) — honest self-reflection without excuses", url: "/en/blog/hansei-honest-self-reflection-without-excuses.html", summary: "Why training without honest recognition of your own mistakes becomes ego defense instead of real correction." },
        { date: "March 18, 2026", title: "One teacher, one transmission", url: "/en/blog/one-teacher-one-transmission.html", summary: "Why one coherent transmission protects learning from confusion, and why senior students support training best by being good uke." },
        { date: "March 18, 2026", title: "Shuhari (守破離) — stages of maturation in training", url: "/en/blog/shuhari-stages-of-maturation-in-training.html", summary: "How faithfully trained form matures into understanding and freedom instead of collapsing into chaos or ego." },
        { date: "March 15, 2026", title: "Shoshin (初心) — beginner's mind", url: "/en/blog/shoshin-beginners-mind.html", summary: "Why real growth begins where experience still refuses to harden into ego, certainty, and routine." },
        { date: "March 14, 2026", title: "Fudōshin (不動心) — immovable mind", url: "/en/blog/fudoshin-immovable-mind.html", summary: "How to preserve stability of decision, breath, and posture when pressure is most likely to break technique." },
        { date: "March 7, 2026", title: "Fumio Toyoda’s Aikido style: technique and Zen as one system", url: "/en/blog/toyoda-aikido-style-technique-and-zen.html", summary: "How Toyoda lineage integrates technical precision, breath work, and Zen discipline into one training method." },
        { date: "March 7, 2026", title: "Toyoda–Germanov lineage: how we train and what sets our school apart", url: "/en/blog/toyoda-germanov-lineage-how-we-train.html", summary: "Our training profile: technical precision, inner discipline, and responsible instructor-led transmission." },
        { date: "March 6, 2026", title: "Hyōshi (拍子) — rhythm and timing of unity", url: "/en/blog/hyoshi-timing-reveals-unity-of-movement.html", summary: "Cutting movement or letting it spill immediately reveals the quality of unity between body, breath, and intent." },
        { date: "March 6, 2026", title: "Ensō (円相) — circle of presence", url: "/en/blog/enso-circle-of-presence.html", summary: "One brushstroke that exposes the quality of mind and decision-making under pressure." },
        { date: "February 25, 2026", title: "Zanshin (残心) — awareness after execution", url: "/en/blog/zanshin-awareness-after-execution.html", summary: "Why many errors happen after action and how to maintain awareness until the process is truly complete." },
        { date: "February 24, 2026", title: "Sesshin (接心) — deep practice and focused mind", url: "/en/blog/sesshin-deep-practice.html", summary: "Why Sesshin is a core training method and a central identity element of Sesshinkan Dojo." },
        { date: "February 23, 2026", title: "Bushido (武士道) — way of the warrior", url: "/en/blog/bushido-way-of-the-warrior.html", summary: "The samurai code and seven virtues that remain practical on the mat, at work, and in daily decisions." },
        { date: "February 23, 2026", title: "Kaizen (改善) — continuous improvement", url: "/en/blog/kaizen-continuous-improvement.html", summary: "Small daily steps that produce durable progress and stronger technical foundations." },
        { date: "February 23, 2026", title: "Gaman (我慢) — endurance and composure", url: "/en/blog/gaman-endurance-and-composure.html", summary: "The art of carrying pressure with dignity, calm, and mature self-control." },
        { date: "February 23, 2026", title: "Kintsugi (金継ぎ) — golden repair", url: "/en/blog/kintsugi-golden-repair.html", summary: "Cracks do not need to be hidden — they can become a source of strength and meaning." },
        { date: "February 23, 2026", title: "Wabi-Sabi (侘寂) — beauty of imperfection", url: "/en/blog/wabi-sabi-beauty-of-imperfection.html", summary: "Accepting simplicity, impermanence, and imperfection as part of authentic growth." },
        { date: "February 23, 2026", title: "Mushin (無心) — no mind", url: "/en/blog/mushin-no-mind.html", summary: "A state of clear presence: no fixation, no noise, and natural action under pressure." },
        { date: "February 23, 2026", title: "Zenshin (前進) — full commitment", url: "/en/blog/zenshin-full-commitment.html", summary: "Consistent forward movement with full attention and ownership of the process." },
        { date: "February 23, 2026", title: "Omoiyari (思いやり) — considerate compassion", url: "/en/blog/omoiyari-considerate-compassion.html", summary: "Empathy in practice: understanding your partner's needs before they are spoken." },
        { date: "February 23, 2026", title: "Jiko Sekinin (自己責任) — personal responsibility", url: "/en/blog/jiko-sekinin-personal-responsibility.html", summary: "Owning decisions, mistakes, and consequences without excuses or blame-shifting." },
        { date: "February 23, 2026", title: "Kuzushi (崩し) — controlled imbalance", url: "/en/blog/kuzushi-controlled-imbalance.html", summary: "On and off the mat: changing force relationships consciously to create room for transformation." }
      ].freeze

      def canonical_url
        path = current_path || ""
        separator = path.empty? || path.start_with?("/") ? "" : "/"
        "#{site_url}#{separator}#{path}"
      end

      def blog_current_page
        path = current_path.to_s
        return 1 if path == "blog.html" || path == "en/blog.html"

        match = path.match(%r{\A(?:en/)?blog-(\d+)\.html\z})
        page = match ? match[1].to_i : 1
        page.positive? ? page : 1
      end

      def blog_posts(language: current_lang)
        language == "en" ? BLOG_POSTS_EN : BLOG_POSTS_PL
      end

      def blog_total_pages(language: current_lang)
        total = (blog_posts(language: language).size.to_f / BLOG_POSTS_PER_PAGE).ceil
        total.positive? ? total : 1
      end

      def blog_posts_for_current_page
        offset = (blog_current_page - 1) * BLOG_POSTS_PER_PAGE
        blog_posts.slice(offset, BLOG_POSTS_PER_PAGE) || []
      end

      def blog_page_numbers(language: current_lang)
        (1..blog_total_pages(language: language)).to_a
      end

      def blog_page_path(page, language: current_lang)
        normalized_page = page.to_i
        normalized_page = 1 if normalized_page < 1

        if language == "en"
          normalized_page == 1 ? "/en/blog.html" : "/en/blog-#{normalized_page}.html"
        else
          normalized_page == 1 ? "/blog.html" : "/blog-#{normalized_page}.html"
        end
      end

      def blog_article_page?
        path = current_path.to_s
        return false if path.empty?

        (path.start_with?("blog/") || path.start_with?("en/blog/")) && !path.match?(%r{\A(?:en/)?blog(?:-\d+)?\.html\z})
      end

      def social_image_for_path(path)
        case path.to_s
        when "blog/enso-krag-obecnosci.html", "en/blog/enso-circle-of-presence.html"
          "images/blog/enso-featured.png"
        when "blog/jeden-nauczyciel-jeden-przekaz.html", "en/blog/one-teacher-one-transmission.html"
          "images/blog/one-teacher-one-transmission-featured.jpeg"
        else
          "images/toyoda.svg"
        end
      end

      def page_social_image_url
        "#{site_url}#{asset_path(social_image_for_path(current_path))}"
      end

      def article_schema_for_current_path
        case current_path.to_s
        when "blog/enso-krag-obecnosci.html"
          article_schema(
            name: "Ensō — krąg obecności i trening decyzji",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-06",
            date_modified: "2026-03-06"
          )
        when "en/blog/enso-circle-of-presence.html"
          article_schema(
            name: "Ensō — circle of presence and decision training",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-06",
            date_modified: "2026-03-06"
          )
        when "blog/hyoshi-rytm-timing-jednosci-ruchu.html"
          article_schema(
            name: "Hyōshi — rytm i timing jedności w Aikido",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-06",
            date_modified: "2026-03-06"
          )
        when "en/blog/hyoshi-timing-reveals-unity-of-movement.html"
          article_schema(
            name: "Hyōshi — rhythm and timing of unity in Aikido",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-06",
            date_modified: "2026-03-06"
          )
        when "blog/fudoshin-niewzruszony-umysl.html"
          article_schema(
            name: "Fudōshin — niewzruszony umysł i stabilność pod presją",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-14",
            date_modified: "2026-03-14"
          )
        when "blog/shoshin-umysl-poczatkujacego.html"
          article_schema(
            name: "Shoshin — umysł początkującego i pokora w rozwoju",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-15",
            date_modified: "2026-03-15"
          )
        when "blog/shuhari-etapy-dojrzewania-w-treningu.html"
          article_schema(
            name: "Shuhari — etapy dojrzewania w treningu i droga do swobody",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-18",
            date_modified: "2026-03-18"
          )
        when "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html"
          article_schema(
            name: "Hansei — uczciwa autorefleksja bez wymówek",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-26",
            date_modified: "2026-03-26"
          )
        when "blog/aiki-harmonia-w-dzialaniu.html"
          article_schema(
            name: "Aiki — harmonia w działaniu, nie w deklaracji",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-04-02",
            date_modified: "2026-04-02"
          )
        when "blog/misogi-oczyszczenie-przez-praktyke.html"
          article_schema(
            name: "Misogi — oczyszczenie przez praktykę",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-04-04",
            date_modified: "2026-04-04"
          )
        when "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html"
          article_schema(
            name: "Ichi-go ichi-e — każde spotkanie zdarza się tylko raz",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-26",
            date_modified: "2026-03-26"
          )
        when "blog/jeden-nauczyciel-jeden-przekaz.html"
          article_schema(
            name: "Jeden nauczyciel, jeden przekaz — porządek nauki w dojo i na seminarium",
            description: page_description,
            image: page_social_image_url,
            lang: "pl",
            date_published: "2026-03-18",
            date_modified: "2026-03-18"
          )
        when "en/blog/fudoshin-immovable-mind.html"
          article_schema(
            name: "Fudōshin — immovable mind and stability under pressure",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-14",
            date_modified: "2026-03-14"
          )
        when "en/blog/shoshin-beginners-mind.html"
          article_schema(
            name: "Shoshin — beginner's mind and humility in growth",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-15",
            date_modified: "2026-03-15"
          )
        when "en/blog/shuhari-stages-of-maturation-in-training.html"
          article_schema(
            name: "Shuhari — stages of maturation in training and the path to freedom",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-18",
            date_modified: "2026-03-18"
          )
        when "en/blog/hansei-honest-self-reflection-without-excuses.html"
          article_schema(
            name: "Hansei — honest self-reflection without excuses",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-26",
            date_modified: "2026-03-26"
          )
        when "en/blog/aiki-harmony-in-action.html"
          article_schema(
            name: "Aiki — harmony in action, not in slogans",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-04-02",
            date_modified: "2026-04-02"
          )
        when "en/blog/misogi-purification-through-practice.html"
          article_schema(
            name: "Misogi — purification through practice",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-04-04",
            date_modified: "2026-04-04"
          )
        when "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html"
          article_schema(
            name: "Ichi-go ichi-e — every encounter happens only once",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-26",
            date_modified: "2026-03-26"
          )
        when "en/blog/one-teacher-one-transmission.html"
          article_schema(
            name: "One teacher, one transmission — order in dojo and seminar learning",
            description: page_description,
            image: page_social_image_url,
            lang: "en",
            date_published: "2026-03-18",
            date_modified: "2026-03-18"
          )
        else
          ""
        end
      end

      LANG_URL_MAP = {
        "index.html" => "en/",
        "" => "en/",
        "kontakt.html" => "en/contact.html",
        "aikido/czym_jest.html" => "en/aikido/what_is.html",
        "aikido/historia.html" => "en/aikido/history.html",
        "aikido/korzysci.html" => "en/aikido/benefits.html",
        "aikido/dla_poczatkujacych.html" => "en/aikido/beginners.html",
        "aikido/aiki_taiso.html" => "en/aikido/aiki_taiso.html",
        "aikido/reishiki.html" => "en/aikido/reishiki.html",
        "aikido/budo_zen.html" => "en/aikido/budo_zen.html",
        "aikido/ki_kokyu.html" => "en/aikido/ki_kokyu.html",
        "slowniczek.html" => "en/glossary.html",
        "wymagania_egzaminacyjne/kyu.html" => "en/requirements/kyu.html",
        "wymagania_egzaminacyjne/dan.html" => "en/requirements/dan.html",
        "lineage.html" => "en/lineage.html",
        "biografie/o-sensei.html" => "en/biographies/o-sensei.html",
        "biografie/kisshomaru.html" => "en/biographies/kisshomaru.html",
        "biografie/moriteru.html" => "en/biographies/moriteru.html",
        "biografie/mitsuteru.html" => "en/biographies/mitsuteru.html",
        "biografie/toyoda.html" => "en/biographies/toyoda.html",
        "biografie/germanov.html" => "en/biographies/germanov.html",
        "biografie/ostrowski.html" => "en/biographies/ostrowski.html",
        "biografie/szrajer.html" => "en/biographies/szrajer.html",
        "wydarzenia/2026.html" => "en/events/2026.html",
        "faq.html" => "en/faq.html",
        "gdynia.html" => "en/gdynia.html",
        "yudansha.html" => "en/yudansha.html",
        "blog.html" => "en/blog.html",
        "blog-2.html" => "en/blog-2.html",
        "blog/bushido-droga-wojownika.html" => "en/blog/bushido-way-of-the-warrior.html",
        "blog/kaizen-ciagle-doskonalenie.html" => "en/blog/kaizen-continuous-improvement.html",
        "blog/gaman-wytrwalosc.html" => "en/blog/gaman-endurance-and-composure.html",
        "blog/kintsugi-zlota-naprawa.html" => "en/blog/kintsugi-golden-repair.html",
        "blog/wabi-sabi-piekno-niedoskonalosci.html" => "en/blog/wabi-sabi-beauty-of-imperfection.html",
        "blog/mushin-umysl-bez-umyslu.html" => "en/blog/mushin-no-mind.html",
        "blog/sesshin-gleboka-praktyka.html" => "en/blog/sesshin-deep-practice.html",
        "blog/zenshin-pelne-zaangazowanie.html" => "en/blog/zenshin-full-commitment.html",
        "blog/zanshin-czujnosc-po-technice.html" => "en/blog/zanshin-awareness-after-execution.html",
        "blog/enso-krag-obecnosci.html" => "en/blog/enso-circle-of-presence.html",
        "blog/hyoshi-rytm-timing-jednosci-ruchu.html" => "en/blog/hyoshi-timing-reveals-unity-of-movement.html",
        "blog/fudoshin-niewzruszony-umysl.html" => "en/blog/fudoshin-immovable-mind.html",
        "blog/shoshin-umysl-poczatkujacego.html" => "en/blog/shoshin-beginners-mind.html",
        "blog/shuhari-etapy-dojrzewania-w-treningu.html" => "en/blog/shuhari-stages-of-maturation-in-training.html",
        "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html" => "en/blog/hansei-honest-self-reflection-without-excuses.html",
        "blog/aiki-harmonia-w-dzialaniu.html" => "en/blog/aiki-harmony-in-action.html",
        "blog/misogi-oczyszczenie-przez-praktyke.html" => "en/blog/misogi-purification-through-practice.html",
        "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html" => "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html",
        "blog/jeden-nauczyciel-jeden-przekaz.html" => "en/blog/one-teacher-one-transmission.html",
        "blog/styl-aikido-fumio-toyody-technika-i-zen.html" => "en/blog/toyoda-aikido-style-technique-and-zen.html",
        "blog/linia-toyoda-germanov-jak-cwiczymy.html" => "en/blog/toyoda-germanov-lineage-how-we-train.html",
        "blog/omoiyari-uwazna-troska.html" => "en/blog/omoiyari-considerate-compassion.html",
        "blog/jiko-sekinin-odpowiedzialnosc-osobista.html" => "en/blog/jiko-sekinin-personal-responsibility.html",
        "blog/kuzushi-kontrolowana-nierownowaga.html" => "en/blog/kuzushi-controlled-imbalance.html",
        "en/" => "",
        "en/index.html" => "",
        "en/contact.html" => "kontakt.html",
        "en/aikido/what_is.html" => "aikido/czym_jest.html",
        "en/aikido/history.html" => "aikido/historia.html",
        "en/aikido/benefits.html" => "aikido/korzysci.html",
        "en/aikido/beginners.html" => "aikido/dla_poczatkujacych.html",
        "en/aikido/aiki_taiso.html" => "aikido/aiki_taiso.html",
        "en/aikido/reishiki.html" => "aikido/reishiki.html",
        "en/aikido/budo_zen.html" => "aikido/budo_zen.html",
        "en/aikido/ki_kokyu.html" => "aikido/ki_kokyu.html",
        "en/glossary.html" => "slowniczek.html",
        "en/requirements/kyu.html" => "wymagania_egzaminacyjne/kyu.html",
        "en/requirements/dan.html" => "wymagania_egzaminacyjne/dan.html",
        "en/lineage.html" => "lineage.html",
        "en/biographies/o-sensei.html" => "biografie/o-sensei.html",
        "en/biographies/kisshomaru.html" => "biografie/kisshomaru.html",
        "en/biographies/moriteru.html" => "biografie/moriteru.html",
        "en/biographies/mitsuteru.html" => "biografie/mitsuteru.html",
        "en/biographies/toyoda.html" => "biografie/toyoda.html",
        "en/biographies/germanov.html" => "biografie/germanov.html",
        "en/biographies/ostrowski.html" => "biografie/ostrowski.html",
        "en/biographies/szrajer.html" => "biografie/szrajer.html",
        "en/events/2026.html" => "wydarzenia/2026.html",
        "en/faq.html" => "faq.html",
        "en/gdynia.html" => "gdynia.html",
        "en/yudansha.html" => "yudansha.html",
        "en/blog.html" => "blog.html",
        "en/blog-2.html" => "blog-2.html",
        "en/blog/bushido-way-of-the-warrior.html" => "blog/bushido-droga-wojownika.html",
        "en/blog/kaizen-continuous-improvement.html" => "blog/kaizen-ciagle-doskonalenie.html",
        "en/blog/gaman-endurance-and-composure.html" => "blog/gaman-wytrwalosc.html",
        "en/blog/kintsugi-golden-repair.html" => "blog/kintsugi-zlota-naprawa.html",
        "en/blog/wabi-sabi-beauty-of-imperfection.html" => "blog/wabi-sabi-piekno-niedoskonalosci.html",
        "en/blog/mushin-no-mind.html" => "blog/mushin-umysl-bez-umyslu.html",
        "en/blog/sesshin-deep-practice.html" => "blog/sesshin-gleboka-praktyka.html",
        "en/blog/zenshin-full-commitment.html" => "blog/zenshin-pelne-zaangazowanie.html",
        "en/blog/zanshin-awareness-after-execution.html" => "blog/zanshin-czujnosc-po-technice.html",
        "en/blog/enso-circle-of-presence.html" => "blog/enso-krag-obecnosci.html",
        "en/blog/hyoshi-timing-reveals-unity-of-movement.html" => "blog/hyoshi-rytm-timing-jednosci-ruchu.html",
        "en/blog/fudoshin-immovable-mind.html" => "blog/fudoshin-niewzruszony-umysl.html",
        "en/blog/shoshin-beginners-mind.html" => "blog/shoshin-umysl-poczatkujacego.html",
        "en/blog/shuhari-stages-of-maturation-in-training.html" => "blog/shuhari-etapy-dojrzewania-w-treningu.html",
        "en/blog/hansei-honest-self-reflection-without-excuses.html" => "blog/hansei-uczciwa-autorefleksja-bez-wymowek.html",
        "en/blog/aiki-harmony-in-action.html" => "blog/aiki-harmonia-w-dzialaniu.html",
        "en/blog/misogi-purification-through-practice.html" => "blog/misogi-oczyszczenie-przez-praktyke.html",
        "en/blog/ichi-go-ichi-e-every-encounter-happens-only-once.html" => "blog/ichi-go-ichi-e-kazde-spotkanie-zdarza-sie-tylko-raz.html",
        "en/blog/one-teacher-one-transmission.html" => "blog/jeden-nauczyciel-jeden-przekaz.html",
        "en/blog/toyoda-aikido-style-technique-and-zen.html" => "blog/styl-aikido-fumio-toyody-technika-i-zen.html",
        "en/blog/toyoda-germanov-lineage-how-we-train.html" => "blog/linia-toyoda-germanov-jak-cwiczymy.html",
        "en/blog/omoiyari-considerate-compassion.html" => "blog/omoiyari-uwazna-troska.html",
        "en/blog/jiko-sekinin-personal-responsibility.html" => "blog/jiko-sekinin-odpowiedzialnosc-osobista.html",
        "en/blog/kuzushi-controlled-imbalance.html" => "blog/kuzushi-kontrolowana-nierownowaga.html",
      }.freeze

      def current_lang
        path = current_path.to_s
        path.start_with?("en/") ? "en" : "pl"
      end

      def alternate_lang
        current_lang == "pl" ? "en" : "pl"
      end

      def alternate_url
        path = current_path.to_s

        if (match = path.match(/\Ablog-(\d+)\.html\z/))
          return "#{site_url}/en/blog-#{match[1]}.html"
        end

        if (match = path.match(%r{\Aen/blog-(\d+)\.html\z}))
          return "#{site_url}/blog-#{match[1]}.html"
        end

        mapped = LANG_URL_MAP[path]
        return nil unless mapped

        url = "#{site_url}/#{mapped}"
        url = url.gsub(%r{(?<!:)/+}, "/")
        url.chomp("/")
      end

      def page_hreflang_tags
        alt_url = alternate_url
        return "" unless alt_url

        if current_lang == "pl"
          <<~HTML
            <link rel="alternate" hreflang="pl" href="#{canonical_url}" />
            <link rel="alternate" hreflang="en" href="#{alt_url}" />
            <link rel="alternate" hreflang="x-default" href="#{canonical_url}" />
          HTML
        else
          <<~HTML
            <link rel="alternate" hreflang="en" href="#{canonical_url}" />
            <link rel="alternate" hreflang="pl" href="#{alt_url}" />
            <link rel="alternate" hreflang="x-default" href="#{alt_url}" />
          HTML
        end
      end

      def asset_path(path)
        if URI(path).absolute?
          path
        else
          assets[path]
        end
      end

      def asset_path_with_version(path)
        base_path = asset_path(path)
        version = Time.now.to_i
        "#{base_path}?v=#{version}"
      end

      def new(**new_options)
        dup.tap do |ctx|
          new_options.each do |key, value|
            ctx.instance_variable_set(:"@#{key}", value)
          end
        end
      end

      def article_schema(name:, description:, image:, lang: "pl", date_published: "2024-01-01", date_modified: "2024-01-01")
        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "Article",
          "headline" => name,
          "description" => description,
          "image" => image,
          "url" => canonical_url,
          "inLanguage" => lang == "pl" ? "pl-PL" : "en-US",
          "author" => {
            "@type" => "Organization",
            "name" => "Polska Organizacja Aikido",
            "url" => site_url
          },
          "publisher" => {
            "@type" => "Organization",
            "name" => site_name,
            "logo" => {
              "@type" => "ImageObject",
              "url" => "#{site_url}#{asset_path('images/toyoda.svg')}"
            }
          },
          "datePublished" => date_published,
          "dateModified" => date_modified
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end

      def event_schema(name:, start_date:, end_date: nil, location:, description:, image:, lang: "pl")
        end_date ||= start_date
        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "Event",
          "name" => name,
          "description" => description,
          "image" => image,
          "url" => canonical_url,
          "startDate" => start_date,
          "endDate" => end_date,
          "inLanguage" => lang == "pl" ? "pl-PL" : "en-US",
          "location" => {
            "@type" => "Place",
            "name" => location[:name],
            "address" => {
              "@type" => "PostalAddress",
              "streetAddress" => location[:street],
              "addressLocality" => location[:city],
              "addressCountry" => location[:country] || "PL"
            }
          },
          "organizer" => {
            "@type" => "Organization",
            "name" => site_name,
            "url" => site_url
          }
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end

      def faq_schema(questions)
        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "FAQPage",
          "mainEntity" => questions.map do |q|
            {
              "@type" => "Question",
              "name" => q[:question],
              "acceptedAnswer" => {
                "@type" => "Answer",
                "text" => q[:answer]
              }
            }
          end
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end

      def breadcrumb_schema(items)
        item_list = items.map.with_index do |item, index|
          {
            "@type" => "ListItem",
            "position" => index + 1,
            "name" => item[:name],
            "item" => item[:url]
          }
        end

        jsonld = {
          "@context" => "https://schema.org",
          "@type" => "BreadcrumbList",
          "itemListElement" => item_list
        }.to_json

        <<~HTML
          <script type="application/ld+json">
          #{jsonld}
          </script>
        HTML
      end
    end
  end
end

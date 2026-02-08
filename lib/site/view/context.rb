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
          [title, site_name].compact.join(" | ")
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

      def canonical_url
        path = current_path || ""
        separator = path.empty? || path.start_with?("/") ? "" : "/"
        "#{site_url}#{separator}#{path}"
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
        "en/" => "",
        "en/index.html" => "",
        "en/contact.html" => "kontakt.html",
        "en/aikido/what_is.html" => "aikido/czym_jest.html",
        "en/aikido/history.html" => "aikido/historia.html",
        "en/aikido/benefits.html" => "aikido/korzysci.html",
        "en/aikido/beginners.html" => "aikido/dla_poczatkujacych.html",
        "en/aikido/aiki_taiso.html" => "aikido/aiki_taiso.html",
        "en/aikido/reishiki.html" => "aikido/reishiki.html",
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
        "en/yudansha.html" => "yudansha.html"
      }.freeze

      def current_lang
        path = current_path.to_s
        path.start_with?("en/") ? "en" : "pl"
      end

      def alternate_lang
        current_lang == "pl" ? "en" : "pl"
      end

      def alternate_url
        mapped = LANG_URL_MAP[current_path.to_s]
        return nil unless mapped
        "#{site_url}/#{mapped}".gsub(%r{//}, "/").gsub(%r{/$}, "")
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

      def article_schema(name:, description:, image:, lang: "pl")
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
          "datePublished" => "2024-01-01",
          "dateModified" => "2024-01-01"
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

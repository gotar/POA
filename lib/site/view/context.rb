require "uri"
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
        @page_title = nil
        @_assets = deps[:assets]
        @_settings = deps[:settings]
      end

      def for_render_env(render_env)
        self.class.new(
          current_path: @current_path,
          render_env: render_env,
          assets: @_assets,
          settings: @_settings
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
          [@page_title, site_name].compact.join(" | ")
        else
          @page_title = new_title
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
    end
  end
end

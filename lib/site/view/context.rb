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
          "Aikido Gdynia, Aikido Trójmiasto, POA, Polska Organizacja Aikido, Sesshinkan Dojo, Toyoda, Germanov, Oskar Szrajer, sztuki walki Gdynia, samoobrona Gdynia, treningi Aikido"
        when "en", "en/"
          "Aikido Gdynia, Aikido Poland, POA, Polish Aikido Organization, Sesshinkan Dojo, Toyoda, Germanov, Oskar Szrajer, martial arts Gdynia, self-defense training, Aikido classes"
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

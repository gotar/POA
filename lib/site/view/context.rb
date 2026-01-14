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

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

      attr_reader :current_path

      def initialize(current_path: nil, render_env: nil, **deps)
        super(render_env: render_env)

        @current_path = current_path
        @page_title = nil
        @_assets = deps[:assets]
        @_settings = deps[:settings]
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

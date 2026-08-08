# Shared setup for the POA test suite.
#
# The suite runs inside the poa-dev:local container (see bin/test); the host
# Ruby on the Steam Deck is not a supported test environment.
#
# We boot the real dry-system container (same path as bin/build) so tests
# exercise the actual wiring: providers, registrations, and view classes.

ENV["EXPORT_DIR"] ||= "build/test-output"
ENV["IMPORT_DIR"] ||= "import"

require "minitest/autorun"
require "ostruct"
require "tmpdir"
require "fileutils"
require "json"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "../system/boot"

# dry-system loads components lazily on first key resolution; force-load the
# ones the suite exercises directly so test order cannot affect results.
require "site/view/context"
require "site/generate"
require "site/assets"
require "site/importers/files"
require "site/prepare"
require "site/exporters/files"

module Site
  module TestHelpers
    # Deterministic assets double: keeps asset URLs predictable and makes the
    # suite independent of the real manifest on disk.
    class FakeAssets
      def [](asset)
        "/assets/#{asset}"
      end

      def read(asset)
        "fake contents of #{asset}"
      end
    end

    DEFAULT_SETTINGS = {
      import_dir: "import",
      export_dir: "build",
      assets_precompiled: false,
      assets_server_url: nil,
      site_name: "Polska Organizacja Aikido",
      site_author: "POA",
      site_url: "https://aikido-polska.eu",
    }.freeze

    def settings(**overrides)
      OpenStruct.new(DEFAULT_SETTINGS.merge(overrides))
    end

    # NOTE: Site::Container["view.context"] returns a prototype *instance*
    # (Context#new on an instance dups it, keeping the container's own
    # assets/settings). Tests instantiate the class directly so injected
    # deps (settings, assets doubles) actually take effect.
    def context_class
      Site::View::Context
    end

    def make_context(current_path: nil, settings: self.settings, assets: FakeAssets.new, page_title: nil, root: Site::Container.config.root)
      context_class.new(
        current_path: current_path,
        root: root,
        assets: assets,
        settings: settings,
        page_title: page_title
      )
    end

    def site_root
      Site::Container.config.root
    end
  end
end

class Minitest::Test
  include Site::TestHelpers
end

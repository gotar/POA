require "pathname"
require "dry/system"

module Site
  class Container < Dry::System::Container
    configure do |config|
      config.root = Pathname(__dir__).join("../..").realpath
      config.component_dirs.add "lib" do |dir|
        dir.namespaces.add "site", key: nil
      end
    end

    def self.build
      self["build"].(config.root)
    end
  end
end

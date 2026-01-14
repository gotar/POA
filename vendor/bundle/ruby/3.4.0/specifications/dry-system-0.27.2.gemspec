# -*- encoding: utf-8 -*-
# stub: dry-system 0.27.2 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-system".freeze
  s.version = "0.27.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-system/issues", "changelog_uri" => "https://github.com/dry-rb/dry-system/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-system" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Solnica".freeze]
  s.date = "2022-10-17"
  s.description = "Organize your code into reusable components".freeze
  s.email = ["piotr.solnica@gmail.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-system".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Organize your code into reusable components".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6".freeze])
  s.add_runtime_dependency(%q<dry-auto_inject>.freeze, [">= 0.4.0".freeze])
  s.add_runtime_dependency(%q<dry-configurable>.freeze, ["~> 0.16".freeze, ">= 0.16.0".freeze])
  s.add_runtime_dependency(%q<dry-container>.freeze, ["~> 0.10".freeze, ">= 0.10.0".freeze])
  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 0.9".freeze, ">= 0.9.0".freeze])
  s.add_runtime_dependency(%q<dry-inflector>.freeze, ["~> 0.1".freeze, ">= 0.1.2".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
end

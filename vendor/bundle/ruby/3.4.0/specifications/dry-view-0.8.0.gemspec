# -*- encoding: utf-8 -*-
# stub: dry-view 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-view".freeze
  s.version = "0.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-view/issues", "changelog_uri" => "https://github.com/dry-rb/dry-view/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-view" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tim Riley".freeze, "Piotr Solnica".freeze]
  s.date = "2024-11-20"
  s.description = "A complete, standalone view rendering system that gives you everything you need to write well-factored view code".freeze
  s.email = ["tim@icelab.com.au".freeze, "piotr.solnica@gmail.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-view".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "A complete, standalone view rendering system that gives you everything you need to write well-factored view code".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<dry-configurable>.freeze, ["~> 0.1".freeze])
  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 0.9".freeze, ">= 0.9".freeze])
  s.add_runtime_dependency(%q<dry-inflector>.freeze, ["~> 0.1".freeze])
  s.add_runtime_dependency(%q<tilt>.freeze, ["~> 2.0".freeze, ">= 2.0.6".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
end

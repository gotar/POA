# -*- encoding: utf-8 -*-
# stub: erbse 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "erbse".freeze
  s.version = "0.1.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Sutterer".freeze]
  s.date = "2020-01-28"
  s.description = "An updated Erubis with block support. Block inheritance soon to come.".freeze
  s.email = ["apotonick@gmail.com".freeze]
  s.homepage = "https://github.com/apotonick/erbse".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.3".freeze
  s.summary = "Updated Erubis.".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<temple>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
end

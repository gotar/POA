# -*- encoding: utf-8 -*-
# stub: guard-shell 0.7.2 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-shell".freeze
  s.version = "0.7.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joshua Hawxwell".freeze, "Codru\u021B Constantin Gu\u0219oi".freeze]
  s.date = "2021-04-11"
  s.description = "    Guard::Shell automatically runs shell commands when watched files are\n    modified.\n".freeze
  s.email = "mail+rubygems@codrut.pro".freeze
  s.homepage = "http://github.com/sdwolfz/guard-shell".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Guard gem for running shell commands".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<guard>.freeze, [">= 2.0.0".freeze])
  s.add_runtime_dependency(%q<guard-compat>.freeze, ["~> 1.0".freeze])
end

#!/usr/bin/env ruby
# Builds the declarative PAGES table for lib/site/generate.rb from the
# current render calls + Import list (behavior-preserving migration).
require "json"

SOURCE = File.read(File.expand_path("../../lib/site/generate.rb", __dir__))

# ivar name -> container key, from the Import[...] block.
import_map = {}
SOURCE.scan(/^\s+(\w+):\s*"([^"]+)"/) do |ivar, key|
  import_map[ivar] = key
end

# path -> ivar, from the render calls (excluding blog index logic).
render_map = {}
SOURCE.scan(/render export_dir, "([^"]+)", (\w+)/) do |path, ivar|
  render_map[path] = ivar
end

pages = {}
render_map.each do |path, ivar|
  key = import_map[ivar]
  raise "no import key for #{ivar} (path #{path})" unless key

  pages[path] = key
end

out = +"PAGES = {\n"
pages.each do |path, key|
  out << "  #{path.inspect} => #{key.inspect},\n"
end
out << "}.freeze\n"

puts out
puts "---"
puts "pages: #{pages.size}, imports used: #{pages.values.uniq.size}"

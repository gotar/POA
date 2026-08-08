#!/usr/bin/env ruby
# Migrates the case/when SEO blocks of lib/site/view/context.rb into data
# tables (lib/site/view/seo_data.rb), preserving behavior 1:1.
#
# Verification is not "trust the script": after regeneration, the fixture
# test (test/seo_snapshot_test.rb) compares runtime behavior for all 156
# paths against the pre-refactor snapshot, and the determinism build diff
# must show zero HTML changes.
#
# Run inside the dev container:
#   docker run --rm -v "$PWD:/app" -w /app poa-dev:local ruby test/scripts/build_seo_data.rb
#
# The generated file is deterministic: regenerating on the same input
# produces identical bytes.

require "json"

CONTEXT_PATH = File.expand_path("../../lib/site/view/context.rb", __dir__)
OUTPUT_PATH = File.expand_path("../../lib/site/view/seo_data.rb", __dir__)
source = File.read(CONTEXT_PATH)

# --- Parse a case/when method body -----------------------------------------

# Returns an array of clauses: { conditions: [String|Regexp source], body: String }
def parse_case_when(source, method_name)
  body = source[/def #{method_name}(?:\(.*?\))?\n(.*?)\n      end\n/m, 1]
  raise "method #{method_name} not found" unless body

  clauses = []
  current = nil

  body.each_line do |line|
    case line
    when /^\s*when\s+(.+)$/
      clauses << (current = { conditions: Regexp.last_match(1), body: [] })
    when /^\s*else\s*$/
      clauses << (current = { conditions: nil, body: [] })
    when /^\s*end\s*$/
      break
    else
      current[:body] << line.strip unless current.nil? || line.strip.empty?
    end
  end

  clauses
end

# Split a `when` condition list on top-level commas. Conditions are simple
# quoted strings or regex literals — no commas inside them.
def split_conditions(condition_source)
  condition_source.split(", ").map(&:strip)
end

# Conditions/values in the source are Ruby string literals (possibly with
# embedded $1 interpolation markers) — unquote them before re-emitting.
def unquote(literal)
  return literal unless literal.start_with?('"')

  literal[1..-2].gsub('\\"', '"').gsub("\\\\", "\\")
end

def parse_value(body_lines)
  unquote(body_lines.join(" "))
end

# --- Emit Ruby source for a data table --------------------------------------

def emit_lookup_table(constant_name, clauses, fallback_source)
  string_entries = {}
  pattern_entries = []

  clauses.each do |clause|
    value = parse_value(clause[:body])

    if clause[:conditions].nil?
      # fallback handled separately
      next
    end

    split_conditions(clause[:conditions]).each do |condition|
      if condition.start_with?("/")
        # regex condition; value may reference $1 -> template lambda
        pattern_entries << [condition, value]
      else
        key = condition == "nil" ? nil : unquote(condition)
        string_entries[key] = value
      end
    end
  end

  out = +"#{constant_name} = {\n"
  string_entries.each do |key, value|
    out << "  #{key.inspect} => #{value.inspect},\n"
  end
  out << "}.freeze\n\n"

  out << "#{constant_name}_PATTERNS = [\n"
  pattern_entries.each do |regex_source, value|
    lambda_body = value.gsub(/\$1/, 'match[1]')
    # Values are repo-owned text without double quotes or backslashes, and
    # #{match[1]} must stay a real interpolation in the generated file.
    out << "  [#{regex_source}, ->(match) { \"#{lambda_body}\" }],\n"
  end
  out << "].freeze\n\n"

  out
end

# --- Extract and emit -------------------------------------------------------

header = <<~HEADER
  # frozen_string_literal: true

  # SEO data tables for Site::View::Context — generated from the case/when
  # blocks by test/scripts/build_seo_data.rb (behavior-preserving migration).
  # Do not edit by hand; regenerate and re-run test/seo_snapshot_test.rb.
  #
  # Fallbacks: DEFAULT_TITLES -> site_name, DEFAULT_DESCRIPTIONS ->
  # page_title, DEFAULT_KEYWORDS -> DEFAULT_KEYWORDS_FALLBACK.
  module Site
    module View
      module SeoData
        DEFAULT_KEYWORDS_FALLBACK = "Aikido, POA, Polska Organizacja Aikido, Polish Aikido Organization, Toyoda, Germanov".freeze

        # Shared lookup: exact path in the data hash wins, then the first
        # matching pattern (template receives the MatchData), then fallback.
        def self.lookup(data, patterns, fallback, path)
          return data[path] if data.key?(path)

          patterns.each do |regex, template|
            if (match = regex.match(path.to_s))
              return template.call(match)
            end
          end

          fallback
        end
HEADER

sections = []

# titles
titles = parse_case_when(source, "default_title_for_path")
fallback = titles.find { |c| c[:conditions].nil? }[:body].join(" ").strip
raise "unexpected title fallback: #{fallback}" unless fallback == "site_name"
sections << emit_lookup_table("DEFAULT_TITLES", titles, fallback)

# descriptions
descriptions = parse_case_when(source, "default_description_for_path")
fallback = descriptions.find { |c| c[:conditions].nil? }[:body].join(" ").strip
raise "unexpected description fallback: #{fallback}" unless fallback == "page_title"
sections << emit_lookup_table("DEFAULT_DESCRIPTIONS", descriptions, fallback)

# keywords
keywords = parse_case_when(source, "default_keywords_for_path")
fallback = keywords.find { |c| c[:conditions].nil? }[:body].join(" ").strip
raise "unexpected keywords fallback: #{fallback}" unless fallback == "DEFAULT_KEYWORDS_FALLBACK" || fallback.start_with?('"Aikido, POA')
sections << emit_lookup_table("DEFAULT_KEYWORDS", keywords, fallback)

# article schema
schema = parse_case_when(source, "article_schema_for_current_path")
schema_entries = {}
schema.each do |clause|
  next if clause[:conditions].nil?

  split_conditions(clause[:conditions]).each do |condition|
    raise "schema condition is a regex: #{condition}" if condition.start_with?("/")

    body = clause[:body].join(" ")
    name = body[/name:\s*(.+?), description:/, 1]
    lang = body[/lang:\s*"([^"]+)"/, 1]
    published = body[/date_published:\s*"([^"]+)"/, 1]
    modified = body[/date_modified:\s*"([^"]+)"/, 1]
    raise "cannot parse schema clause for #{condition}: #{body}" unless name && lang && published && modified

    schema_entries[unquote(condition)] = {
      name: unquote(name),
      lang: lang,
      date_published: published,
      date_modified: modified,
    }
  end
end

schema_src = +"ARTICLE_SCHEMA_DATA = {\n"
schema_entries.each do |path, entry|
  schema_src << "  #{path.inspect} => {\n"
  schema_src << "    name: #{entry[:name].inspect},\n"
  schema_src << "    lang: #{entry[:lang].inspect},\n"
  schema_src << "    date_published: #{entry[:date_published].inspect},\n"
  schema_src << "    date_modified: #{entry[:date_modified].inspect},\n"
  schema_src << "  },\n"
end
schema_src << "}.freeze\n"
sections << schema_src

footer = "    end\n  end\nend\n"

File.write(OUTPUT_PATH, header + sections.join("\n") + footer)
puts "wrote #{OUTPUT_PATH} (#{File.size(OUTPUT_PATH)} bytes)"
puts "titles: #{source.scan(/when "([^"]+)"\n/).size} when-clauses"

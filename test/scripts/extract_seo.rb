#!/usr/bin/env ruby
# Extracts the CURRENT SEO behavior of Site::View::Context into a JSON
# snapshot (test/fixtures/seo_snapshot.json).
#
# Run inside the dev container:
#   docker run --rm -v "$PWD:/app" -w /app poa-dev:local ruby test/scripts/extract_seo.rb
#
# The snapshot is the regression contract: seo_snapshot_test.rb compares
# runtime behavior against it, and determinism_test.rb uses it as the
# independent oracle for the full set of renderable pages. Regenerate it
# whenever the page set or any SEO data changes (see README).

require "bundler/setup"
require "json"
require_relative "../../system/boot"

require "site/view/context"
require "site/generate"

# --- 1. The full set of paths the site can render -------------------------

paths = []

# Static + article pages from the declarative PAGES table. The table order
# matches the render order, so the snapshot's key order stays stable.
paths.concat(Site::Generate::PAGES.keys)

# Blog pagination pages (derived from the BLOG_POSTS counts).
%w[pl en].each do |lang|
  posts = lang == "pl" ? Site::View::Context::BLOG_POSTS_PL : Site::View::Context::BLOG_POSTS_EN
  total = (posts.size.to_f / Site::View::Context::BLOG_POSTS_PER_PAGE).ceil
  total = 1 if total < 1
  (1..total).each do |page|
    paths << (lang == "pl" ? (page == 1 ? "blog.html" : "blog-#{page}.html")
                           : (page == 1 ? "en/blog.html" : "en/blog-#{page}.html"))
  end
end

# Blog article pages.
(Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN).each do |post|
  paths << post[:url].sub(%r{\A/}, "")
end

# Edge paths.
paths << ""
paths << "index.html"

paths.uniq!

# --- 2. Snapshot runtime behavior per path ---------------------------------

settings = OpenStruct.new(
  import_dir: "import",
  export_dir: "build",
  assets_precompiled: false,
  assets_server_url: nil,
  site_name: "Polska Organizacja Aikido",
  site_author: "POA",
  site_url: "https://aikido-polska.eu"
)

class FakeAssets
  def [](asset) = "/assets/#{asset}"
  def read(asset) = "fake"
end

snapshot = {}
paths.each do |path|
  ctx = Site::View::Context.new(
    current_path: path,
    root: Site::Container.config.root,
    assets: FakeAssets.new,
    settings: settings
  )

  entry = {}
  entry["title"] = ctx.default_title_for_path(path)
  entry["description"] = ctx.default_description_for_path(path)
  entry["keywords"] = ctx.default_keywords_for_path(path)

  schema_html = ctx.article_schema_for_current_path
  if schema_html.to_s.strip.empty?
    entry["schema"] = nil
  else
    jsonld = schema_html[/\{.*\}/m]
    parsed = JSON.parse(jsonld)
    entry["schema"] = {
      "headline" => parsed["headline"],
      "inLanguage" => parsed["inLanguage"],
      "datePublished" => parsed["datePublished"],
      "dateModified" => parsed["dateModified"],
    }
  end

  snapshot[path] = entry
end

fixture_path = File.expand_path("../fixtures/seo_snapshot.json", __dir__)
FileUtils.mkdir_p(File.dirname(fixture_path))
File.write(fixture_path, JSON.pretty_generate(snapshot) + "\n")
puts "snapshot written: #{fixture_path} (#{snapshot.size} paths, #{File.size(fixture_path)} bytes)"

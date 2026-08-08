require_relative "test_helper"

# Content-coverage lock: every blog post in BLOG_POSTS_PL / BLOG_POSTS_EN
# must have an Article JSON-LD schema emitted by
# Context#article_schema_for_current_path. Missing entries are a content
# bug (pages without structured data for search engines).
#
# If a post intentionally must not get a schema, add it to
# ARTICLE_SCHEMA_EXCEPTIONS with a comment explaining why — the allowlist
# is meant to stay empty.
class BlogSchemaCoverageTest < Minitest::Test
  # Posts excluded from the Article schema requirement, with reason.
  # Keep empty unless there is a documented reason.
  ARTICLE_SCHEMA_EXCEPTIONS = [].freeze

  SITE_URL = "https://aikido-polska.eu"
  FIXTURE_PATH = File.expand_path("fixtures/seo_snapshot.json", __dir__)

  def fixture
    @fixture ||= JSON.parse(File.read(FIXTURE_PATH))
  end

  def all_posts
    Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN
  end

  # Renders the Article schema for a post path and returns the parsed JSON-LD.
  # Fails the test when no schema is emitted or the JSON does not parse.
  def parse_article_schema(path)
    html = make_context(current_path: path).article_schema_for_current_path
    refute_empty html.to_s.strip, "no Article JSON-LD emitted for #{path}"
    JSON.parse(html[/\{.*\}/m])
  end

  # Mirrors Context#social_image_for_path — the featured image per post.
  def expected_social_image(path)
    case path
    when "blog/enso-krag-obecnosci.html", "en/blog/enso-circle-of-presence.html"
      "images/blog/enso-featured.png"
    when "blog/jeden-nauczyciel-jeden-przekaz.html", "en/blog/one-teacher-one-transmission.html"
      "images/blog/one-teacher-one-transmission-featured.jpeg"
    else
      "images/toyoda.svg"
    end
  end

  def test_every_blog_post_has_article_schema
    missing = []

    all_posts.each do |post|
      path = post[:url].sub(%r{\A/}, "")
      next if ARTICLE_SCHEMA_EXCEPTIONS.include?(path)

      ctx = make_context(current_path: path)
      schema_html = ctx.article_schema_for_current_path
      next unless schema_html.to_s.strip.empty?

      missing << path
    end

    assert_empty missing,
                 "blog posts without Article JSON-LD (add schema data or document an exception):\n#{missing.join("\n")}"
  end

  # Structural lock for EVERY post: the schema must carry the full Article
  # shape (description, image, url, author, publisher, dates, language),
  # cross-checked against the BLOG_POSTS / ARTICLE_SCHEMA_DATA / SEO snapshot
  # data sources. A mere presence check would let a half-built schema through.
  def test_every_blog_post_emits_full_article_schema_structure
    problems = []

    all_posts.each do |post|
      path = post[:url].sub(%r{\A/}, "")
      next if ARTICLE_SCHEMA_EXCEPTIONS.include?(path)

      begin
        jsonld = parse_article_schema(path)
      rescue Minitest::Assertion, JSON::ParserError => e
        problems << "#{path}: #{e.message}"
        next
      end

      lang = path.start_with?("en/") ? "en-US" : "pl-PL"
      data = Site::View::SeoData::ARTICLE_SCHEMA_DATA[path]
      expected_description = fixture.dig(path, "description")

      problems << "#{path}: @context is #{jsonld['@context'].inspect}" unless jsonld["@context"] == "https://schema.org"
      problems << "#{path}: @type is #{jsonld['@type'].inspect}" unless jsonld["@type"] == "Article"
      problems << "#{path}: headline missing" if jsonld["headline"].to_s.strip.empty?
      problems << "#{path}: headline #{jsonld['headline'].inspect} != SEO name #{data && data[:name].inspect}" unless data && jsonld["headline"] == data[:name]
      problems << "#{path}: description missing" if jsonld["description"].to_s.strip.empty?
      problems << "#{path}: description diverged from SEO snapshot" unless jsonld["description"] == expected_description
      expected_image = "#{SITE_URL}/assets/#{expected_social_image(path)}"
      problems << "#{path}: image #{jsonld['image'].inspect} != #{expected_image.inspect}" unless jsonld["image"] == expected_image
      expected_url = "#{SITE_URL}/#{path}"
      problems << "#{path}: url #{jsonld['url'].inspect} != #{expected_url.inspect}" unless jsonld["url"] == expected_url
      problems << "#{path}: inLanguage #{jsonld['inLanguage'].inspect} != #{lang.inspect}" unless jsonld["inLanguage"] == lang

      expected_author = { "@type" => "Organization", "name" => "Polska Organizacja Aikido", "url" => SITE_URL }
      problems << "#{path}: author #{jsonld['author'].inspect}" unless jsonld["author"] == expected_author

      expected_publisher = {
        "@type" => "Organization",
        "name" => "Polska Organizacja Aikido",
        "logo" => { "@type" => "ImageObject", "url" => "#{SITE_URL}/assets/images/toyoda.svg" }
      }
      problems << "#{path}: publisher #{jsonld['publisher'].inspect}" unless jsonld["publisher"] == expected_publisher

      expected_published = data && data[:date_published]
      expected_modified = data && data.fetch(:date_modified, data[:date_published])
      problems << "#{path}: datePublished #{jsonld['datePublished'].inspect} != #{expected_published.inspect}" unless expected_published && jsonld["datePublished"] == expected_published
      problems << "#{path}: dateModified #{jsonld['dateModified'].inspect} != #{expected_modified.inspect}" unless expected_modified && jsonld["dateModified"] == expected_modified
    end

    assert_empty problems, "Article schema structure problems (#{problems.size}):\n#{problems.first(30).join("\n")}"
  end

  # Exact full-content lock on a representative PL article (featured image
  # special case) — the whole JSON-LD object must equal the expected shape.
  def test_full_article_schema_content_sample_pl
    path = "blog/enso-krag-obecnosci.html"
    post = Site::View::Context::BLOG_POSTS_PL.find { |entry| entry[:url] == "/#{path}" }
    data = Site::View::SeoData::ARTICLE_SCHEMA_DATA.fetch(path)

    refute_nil post, "fixture post #{path} must exist in BLOG_POSTS_PL"

    expected = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => data[:name],
      "description" => fixture.dig(path, "description"),
      "image" => "#{SITE_URL}/assets/images/blog/enso-featured.png",
      "url" => "#{SITE_URL}/#{path}",
      "inLanguage" => "pl-PL",
      "author" => { "@type" => "Organization", "name" => "Polska Organizacja Aikido", "url" => SITE_URL },
      "publisher" => {
        "@type" => "Organization",
        "name" => "Polska Organizacja Aikido",
        "logo" => { "@type" => "ImageObject", "url" => "#{SITE_URL}/assets/images/toyoda.svg" }
      },
      "datePublished" => data[:date_published],
      "dateModified" => data[:date_modified]
    }

    assert_equal expected, parse_article_schema(path)
  end

  # Same exact lock for the EN mirror (language + url differ).
  def test_full_article_schema_content_sample_en
    path = "en/blog/enso-circle-of-presence.html"
    post = Site::View::Context::BLOG_POSTS_EN.find { |entry| entry[:url] == "/#{path}" }
    data = Site::View::SeoData::ARTICLE_SCHEMA_DATA.fetch(path)

    refute_nil post, "fixture post #{path} must exist in BLOG_POSTS_EN"

    expected = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => data[:name],
      "description" => fixture.dig(path, "description"),
      "image" => "#{SITE_URL}/assets/images/blog/enso-featured.png",
      "url" => "#{SITE_URL}/#{path}",
      "inLanguage" => "en-US",
      "author" => { "@type" => "Organization", "name" => "Polska Organizacja Aikido", "url" => SITE_URL },
      "publisher" => {
        "@type" => "Organization",
        "name" => "Polska Organizacja Aikido",
        "logo" => { "@type" => "ImageObject", "url" => "#{SITE_URL}/assets/images/toyoda.svg" }
      },
      "datePublished" => data[:date_published],
      "dateModified" => data[:date_modified]
    }

    assert_equal expected, parse_article_schema(path)
  end

  def test_article_schema_contains_headline_and_dates
    ctx = make_context(current_path: "blog/enso-krag-obecnosci.html")
    html = ctx.article_schema_for_current_path

    assert_includes html, "application/ld+json"
    assert_includes html, "Ensō — krąg obecności i trening decyzji"
    assert_includes html, "2026-03-06"
    assert_includes html, "pl-PL"
  end

  def test_article_schema_for_en_article_uses_en_us_language
    ctx = make_context(current_path: "en/blog/enso-circle-of-presence.html")
    html = ctx.article_schema_for_current_path

    assert_includes html, "en-US"
  end

  def test_non_article_path_has_no_schema
    ctx = make_context(current_path: "kontakt.html")

    assert_equal "", ctx.article_schema_for_current_path
  end
end

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

  def test_every_blog_post_has_article_schema
    missing = []

    (Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN).each do |post|
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

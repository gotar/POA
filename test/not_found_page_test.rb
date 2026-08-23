require_relative "test_helper"

# Contract for the custom 404 page:
# - it is rendered through the full PL site layout (GitHub Pages serves it for
#   every unknown URL, so it must carry the real navigation),
# - its SEO defaults are pinned in the data tables,
# - it is EXCLUDED from sitemap.xml (an error page is not site content; a
#   leak here is an SEO regression).
class NotFoundPageTest < Minitest::Test
  def test_404_is_registered_in_pages_table
    assert_equal "views.not_found", Site::Generate::PAGES["404.html"]
  end

  def test_seo_defaults_are_pinned
    ctx = make_context(current_path: "404.html")

    assert_equal "Nie znaleziono strony (404) | Polska Organizacja Aikido", ctx.default_title_for_path("404.html")
    assert_includes ctx.default_description_for_path("404.html"), "Strona nie istnieje"
    refute_empty ctx.default_keywords_for_path("404.html")
  end

  def test_generated_sitemap_excludes_404
    # Render stores processed paths ("index.html" -> "", "en/index.html" -> "en").
    xml = Site::Sitemap.new.call([["", nil], ["en", nil], ["404.html", nil]])

    assert_includes xml, "<loc>https://aikido-polska.eu/</loc>"
    assert_includes xml, "<loc>https://aikido-polska.eu/en/</loc>"
    refute_includes xml, "404.html"
  end

  def test_sitemap_exclusion_list_is_not_empty
    assert_equal ["/404.html"], Site::Sitemap::EXCLUDED
  end
end

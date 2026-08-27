require_relative "test_helper"
require "open3"

# Contract for the custom 404 page:
# - it is rendered through the full PL site layout (GitHub Pages serves it for
#   every unknown URL, so it must carry the real navigation),
# - its SEO defaults are pinned in the data tables,
# - it is EXCLUDED from sitemap.xml (an error page is not site content; a
#   leak here is an SEO regression).
# - since GitHub Pages serves a single 404.html for the whole site, the
#   template must be bilingual (PL + EN section with lang="en") so EN users
#   who hit /en/* 404 receive actionable links.
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

  def test_404_template_is_bilingual
    template = File.read(site_root.join("templates/404.html.erb"))

    assert_includes template, 'lang="en"', "404 template must expose an English section with lang=\"en\""
    assert_includes template, "page not found", "404 template must contain the English heading"
    assert_includes template, 'href="/en/"', "EN block must link to /en/"
    assert_includes template, 'href="/en/gdynia.html"', "EN block must link to EN Gdynia"
    assert_includes template, 'href="/en/contact.html"', "EN block must link to EN contact"
  end

  def test_generated_404_contains_both_languages_and_lang_attribute
    Dir.mktmpdir("poa-404-bilingual-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )

      assert status.success?, "expected build to pass:\n#{output}"

      html = File.read(File.join(export_dir, "404.html"))

      assert_includes html, "nie znaleziono strony", "built 404 must keep the Polish heading"
      assert_includes html, "page not found", "built 404 must render the English heading"
      assert_includes html, 'lang="en"', "built 404 must annotate the English block with lang=\"en\""
      assert_includes html, 'href="/en/"', "built 404 must expose the EN home link"
      assert_includes html, 'href="/en/contact.html"', "built 404 must expose the EN contact link"
    end
  end

  def test_404_bilingual_styles_are_present
    css = File.read(site_root.join("assets/style.css"))

    assert_includes css, ".error-page hr {", "404 divider must be styled"
    assert_includes css, '.error-page section[lang="en"] h2 {', "EN heading in 404 must have a typographic rule"
  end
end

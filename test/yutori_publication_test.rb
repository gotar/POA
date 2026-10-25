require_relative "test_helper"
require "open3"

class YutoriPublicationTest < Minitest::Test
  SITE_URL = "https://aikido-polska.eu"
  PUBLICATION_DATE = "2026-10-17"
  ARTICLES = [
    {
      path: "blog/yutori-zostaw-miejsce-na-korekte.html",
      listing: "blog.html", date: "17 października 2026", language: "pl-PL",
      alternate: "en/blog/yutori-room-to-adjust.html", alternate_language: "en"
    },
    {
      path: "en/blog/yutori-room-to-adjust.html",
      listing: "en/blog.html", date: "October 17, 2026", language: "en-US",
      alternate: "blog/yutori-zostaw-miejsce-na-korekte.html", alternate_language: "pl"
    }
  ].freeze

  def test_rendered_publication_metadata_and_language_pairing
    Dir.mktmpdir("yutori-publication-") do |export_root|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_root },
        File.join(site_root, "bin/build"), chdir: site_root.to_s
      )
      assert status.success?, "site build failed:\n#{output}"
      sitemap = File.read(File.join(export_root, "sitemap.xml"))

      ARTICLES.each do |article|
        url = "#{SITE_URL}/#{article[:path]}"
        html = File.read(File.join(export_root, article[:path]))
        assert_includes html, article[:date], "#{article[:path]}: visible publication date"

        schemas = html.scan(/<script\b[^>]*type="application\/ld\+json"[^>]*>(.*?)<\/script>/m)
                      .map { |body| JSON.parse(body.first) }
        schema = schemas.find { |entry| entry["@type"] == "Article" }
        refute_nil schema, "#{article[:path]}: missing Article JSON-LD"
        assert_equal PUBLICATION_DATE, schema["datePublished"], "#{article[:path]}: datePublished"
        assert_equal PUBLICATION_DATE, schema["dateModified"], "#{article[:path]}: dateModified"
        assert_equal url, schema["url"]
        assert_equal article[:language], schema["inLanguage"]

        links = html.scan(/<link\b[^>]*>/)
        canonical = links.find { |tag| tag.include?('rel="canonical"') }
        refute_nil canonical, "#{article[:path]}: missing canonical"
        assert_includes canonical, "href=\"#{url}\""
        alternate = links.find do |tag|
          tag.include?('rel="alternate"') && tag.include?("hreflang=\"#{article[:alternate_language]}\"")
        end
        refute_nil alternate, "#{article[:path]}: missing paired hreflang"
        assert_includes alternate, "href=\"#{SITE_URL}/#{article[:alternate]}\""

        listing = File.read(File.join(export_root, article[:listing]))
        card = listing.scan(/<article\b[^>]*>.*?<\/article>/m).find do |entry|
          entry.include?("href=\"/#{article[:path]}\"")
        end
        refute_nil card, "#{article[:listing]}: missing Yutori card"
        assert_includes card, article[:date], "#{article[:listing]}: Yutori date"

        sitemap_entry = sitemap.scan(/<url>.*?<\/url>/m).find { |entry| entry.include?("<loc>#{url}</loc>") }
        refute_nil sitemap_entry, "#{article[:path]}: missing sitemap entry"
        assert_includes sitemap_entry, "<lastmod>#{PUBLICATION_DATE}</lastmod>"
      end
    end
  end
end

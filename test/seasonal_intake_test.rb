require_relative "test_helper"
require "open3"
require "site/sitemap"

class SeasonalIntakeTest < Minitest::Test
  PAGES = {
    "index.html" => ["Nowy sezon", "przez cały rok", "hero-actions"],
    "en/index.html" => ["new season", "throughout the year", "hero-actions"],
    "gdynia.html" => ["Nowy sezon", "przez cały rok", "dojo-highlights"],
    "en/gdynia.html" => ["new season", "throughout the year", "dojo-highlights"],
    "pierwszy-trening-aikido-gdynia.html" => ["Nowy sezon", "przez cały rok", "<h2>"]
  }.freeze

  def test_rendered_seasonal_invitation_includes_year_round_intake_in_same_paragraph
    Dir.mktmpdir("poa-seasonal-intake-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )
      assert status.success?, "expected build to pass:\n#{output}"

      PAGES.each do |path, (season, intake, following)|
        html = File.read(File.join(export_dir, path))
        paragraphs = html.scan(/<p\b[^>]*>.*?<\/p>/m)
        seasonal = paragraphs.select { |paragraph| paragraph.include?(season) }
        assert_equal 1, seasonal.length, "#{path}: expected one seasonal invitation"
        paragraph = seasonal.first
        assert_includes paragraph, intake, "#{path}: intake must accompany the invitation"
        refute_match(/\b20\d{2}\b|wrze[śs]|september|new beginner groups|nowe grupy/i, paragraph)
        assert_operator html.index(paragraph), :<, html.index(following), path

        if path.end_with?("index.html")
          assert_match(/\A<p class="hero-description">/, paragraph, path)
          assert_includes paragraph, "Fumio Toyod", "#{path}: preserve lineage"
        else
          lead = paragraphs.find { |candidate| candidate.start_with?('<p class="lead">') }
          refute_nil lead, "#{path}: expected a lead paragraph"
          assert_match(/#{Regexp.escape(lead)}\s*#{Regexp.escape(paragraph)}/m, html, path)
        end
      end
    end
  end

  def test_changed_pages_have_explicit_sitemap_lastmod
    PAGES.each_key do |path|
      url = "/#{path}".sub(/index\.html\z/, "")
      assert_equal "2026-09-11", Site::Sitemap::META.fetch(url).last, url
    end
    assert_equal "2026-04-20", Site::Sitemap::META.fetch("/treningi-aikido-gdynia.html").last
  end
end

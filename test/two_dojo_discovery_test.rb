require_relative "test_helper"
require "open3"

class TwoDojoDiscoveryTest < Minitest::Test
  def setup
    @output = Dir.mktmpdir("poa-two-dojo-")
    output, status = Open3.capture2e(
      { "EXPORT_DIR" => @output },
      File.join(site_root, "bin/build"),
      chdir: site_root.to_s
    )
    assert status.success?, "expected site build to pass:\n#{output}"
  end

  def teardown
    FileUtils.remove_entry(@output) if @output && Dir.exist?(@output)
  end

  def test_generated_dojo_pages_include_city_details_and_routes
    pl = File.read(File.join(@output, "raciborz.html"))
    en = File.read(File.join(@output, "en/raciborz.html"))
    assert_includes pl, "Krzysztof Seget"
    assert_includes pl, "724 940 651"
    assert_includes pl, "Słowackiego 48"
    assert_includes pl, "17:30"
    assert_includes en, "Krzysztof Seget"
    assert_includes en, "724 940 651"
    assert_includes en, "Słowackiego 48"
    assert_includes en, "17:30–19:30"
    assert_includes pl, "tel:+48724940651"
    assert_includes pl, "https://www.google.com/maps/dir/?api=1&amp;destination="
  end

  def test_generated_home_contact_pages_and_sitemap_are_present
    %w[index.html en/index.html kontakt.html en/contact.html raciborz.html en/raciborz.html].each do |path|
      assert File.file?(File.join(@output, path)), "expected generated #{path}"
    end

    ["index.html", "en/index.html"].each do |path|
      html = File.read(File.join(@output, path))
      assert_includes html, "raciborz.html"
      assert_includes html, "Gdynia"
      assert_includes html, "Racibórz"
    end
    ["kontakt.html", "en/contact.html"].each do |path|
      refute_includes File.read(File.join(@output, path)).downcase, "classes suspended"
    end
    sitemap = File.read(File.join(@output, "sitemap.xml"))
    assert_includes sitemap, "/raciborz.html"
    assert_includes sitemap, "/en/raciborz.html"
  end
end

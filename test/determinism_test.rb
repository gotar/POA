require_relative "test_helper"

# The acceptance criterion: the generator must be deterministic. Two full
# builds from the same source must produce byte-identical trees, and the
# generated page set must match the declarative PAGES table plus the blog
# pagination logic.
class DeterminismTest < Minitest::Test
  FIXTURE_PATH = File.expand_path("fixtures/seo_snapshot.json", __dir__)

  def setup
    @generate = Site::Container["generate"]
  end

  def stub_export_dir(dir)
    @generate.define_singleton_method(:settings) { OpenStruct.new(export_dir: dir) }
  end

  def tree_digest(dir)
    Dir[File.join(dir, "**", "*")]
      .select { |path| File.file?(path) }
      .map { |path| [path.sub(%r{\A#{Regexp.escape(dir)}/}, ""), Digest::MD5.file(path).hexdigest] }
      .sort
  end

  def test_two_builds_produce_identical_trees
    stub_export_dir("build/det-a")
    @generate.call(site_root)
    stub_export_dir("build/det-b")
    @generate.call(site_root)

    assert_equal tree_digest(File.join(site_root, "build/det-a")),
                 tree_digest(File.join(site_root, "build/det-b"))
  ensure
    FileUtils.remove_entry(File.join(site_root, "build/det-a")) if Dir.exist?(File.join(site_root, "build/det-a"))
    FileUtils.remove_entry(File.join(site_root, "build/det-b")) if Dir.exist?(File.join(site_root, "build/det-b"))
  end

  def test_build_output_matches_pages_table_and_blog_pagination
    stub_export_dir("build/det-c")
    @generate.call(site_root)

    export_dir = File.join(site_root, "build/det-c")
    rendered = Dir[File.join(export_dir, "**", "*.html")].map { |p| p.sub(%r{\A#{Regexp.escape(export_dir)}/}, "") }

    expected = Site::Generate::PAGES.keys.dup
    %w[pl en].each do |lang|
      pages = make_context(current_path: lang == "pl" ? "blog.html" : "en/blog.html").blog_total_pages(language: lang)
      (1..pages).each do |page|
        expected << if lang == "pl"
                      page == 1 ? "blog.html" : "blog-#{page}.html"
                    else
                      page == 1 ? "en/blog.html" : "en/blog-#{page}.html"
                    end
      end
    end

    assert_equal expected.sort, rendered.sort,
                 "generated html set diverged from PAGES table + blog pagination"
  ensure
    FileUtils.remove_entry(File.join(site_root, "build/det-c")) if Dir.exist?(File.join(site_root, "build/det-c"))
  end

  # NOT tautological: the expected set comes from the checked-in SEO snapshot
  # (captured from master) + the asset copy rules — NOT from PAGES. Removing
  # an entry from the PAGES table makes PAGES and the rendered output shrink
  # together, so a PAGES-derived expectation cannot catch the loss; the
  # snapshot-derived one can (fixture still lists the page, build no longer
  # emits it). Conversely an unlisted render target shows up as an extra file.
  def test_build_output_matches_snapshot_pages_and_asset_copy_rules
    stub_export_dir("build/det-d")
    @generate.call(site_root)

    export_dir = File.join(site_root, "build/det-d")
    actual = Dir.glob(File.join(export_dir, "**", "*"), File::FNM_DOTMATCH)
                .select { |p| File.file?(p) }
                .map { |p| p.sub(%r{\A#{Regexp.escape(export_dir)}/}, "") }

    # Independent oracle 1: every renderable HTML page, pinned by the SEO
    # snapshot fixture (includes blog pagination + all article pages).
    fixture = JSON.parse(File.read(FIXTURE_PATH))
    expected = fixture.keys.select { |path| path.end_with?(".html") }

    # Independent oracle 2: generated sitemap.
    expected << "sitemap.xml"

    # Independent oracle 3: copied static assets, derived from the source
    # assets/ tree per the copy rules in Generate#copy_static_assets.
    root = site_root
    images_root = File.join(root, "assets/images")
    expected.concat(
      Dir.glob(File.join(images_root, "**", "*"))
         .select { |f| File.file?(f) }
         .map { |f| "assets/images/#{f.sub(%r{\A#{Regexp.escape(images_root)}/}, "")}" }
    )
    expected.concat Dir.glob(File.join(root, "assets/favicons", "*")).map { |f| File.basename(f) }
    expected.concat %w[assets/style.css assets/app.js assets/manifest.json robots.txt .nojekyll CNAME]

    assert_equal expected.sort, actual.sort,
                 "build output diverged from snapshot page set or asset copy rules " \
                 "(missing = #{expected.sort - actual.sort}, extra = #{actual.sort - expected.sort})"
  ensure
    FileUtils.remove_entry(File.join(site_root, "build/det-d")) if Dir.exist?(File.join(site_root, "build/det-d"))
  end
end

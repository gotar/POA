require_relative "test_helper"

# The acceptance criterion: the generator must be deterministic. Two full
# builds from the same source must produce byte-identical trees, and the
# generated page set must match the declarative PAGES table plus the blog
# pagination logic.
class DeterminismTest < Minitest::Test
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
end

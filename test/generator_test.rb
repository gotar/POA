require_relative "test_helper"

# Regression tests for Site::Generate and Site::Prepare path handling.
#
# Bugs fixed:
# - File.join(root, export_dir) silently dropped absolute EXPORT_DIR/IMPORT_DIR
#   values (File.join("/app", "/tmp/x") => "/app/tmp/x"), so builds with an
#   absolute export dir wrote into <root>/tmp/... while --clean removed the
#   intended target. Path resolution now goes through File.expand_path.
# - Blog pagination count was duplicated between Generate#total_blog_pages_for
#   and Context#blog_total_pages; Context is the single source of truth.
class GeneratePathsTest < Minitest::Test
  def setup
    @generate = Site::Container["generate"]
    @prepare = Site::Container["prepare"]
  end

  def stub_settings(object, **values)
    object.define_singleton_method(:settings) { OpenStruct.new(values) }
  end

  def test_export_dir_for_keeps_relative_path_under_root
    stub_settings(@generate, export_dir: "build")

    assert_equal "/srv/site/build", @generate.send(:export_dir_for, "/srv/site")
  end

  def test_export_dir_for_honors_absolute_path
    stub_settings(@generate, export_dir: "/tmp/poa-export-absolute")

    assert_equal "/tmp/poa-export-absolute", @generate.send(:export_dir_for, "/srv/site")
  end

  def test_import_dir_for_keeps_relative_path_under_root
    stub_settings(@prepare, import_dir: "import")

    assert_equal "/srv/site/import", @prepare.send(:import_dir_for, "/srv/site")
  end

  def test_import_dir_for_honors_absolute_path
    stub_settings(@prepare, import_dir: "/tmp/poa-import-absolute")

    assert_equal "/tmp/poa-import-absolute", @prepare.send(:import_dir_for, "/srv/site")
  end

  def test_build_with_absolute_export_dir_writes_to_that_dir
    export_root = Dir.mktmpdir("poa-abs-export-")
    export_dir = File.join(export_root, "site")
    stub_settings(@generate, export_dir: export_dir)

    @generate.call(site_root)

    assert File.file?(File.join(export_dir, "index.html")), "expected build output in absolute export dir"
    assert File.file?(File.join(export_dir, "blog.html")), "expected blog index in absolute export dir"
    refute Dir.exist?(File.join(site_root, "tmp")), "no stray <root>/tmp tree may appear"
  ensure
    FileUtils.remove_entry(export_root) if export_root && Dir.exist?(export_root)
  end
end

class GeneratePaginationTest < Minitest::Test
  # Context#blog_total_pages is the single source of truth for blog
  # pagination (Generate#render_blog_index_pages delegates to it). These
  # tests lock the formula so a change in BLOG_POSTS count or per-page size
  # cannot silently break the generated blog-*.html set.
  def test_blog_total_pages_pl_matches_post_count
    expected = (Site::View::Context::BLOG_POSTS_PL.size.to_f / Site::View::Context::BLOG_POSTS_PER_PAGE).ceil

    assert_equal expected, make_context(current_path: "blog.html").blog_total_pages(language: "pl")
  end

  def test_blog_total_pages_en_matches_post_count
    expected = (Site::View::Context::BLOG_POSTS_EN.size.to_f / Site::View::Context::BLOG_POSTS_PER_PAGE).ceil

    assert_equal expected, make_context(current_path: "en/blog.html").blog_total_pages(language: "en")
  end

  def test_blog_total_pages_is_at_least_one_for_empty_posts
    ctx = make_context(current_path: "blog.html")
    ctx.define_singleton_method(:blog_posts) { |**| [] }

    assert_equal 1, ctx.blog_total_pages(language: "pl")
  end

  def test_blog_page_paths_follow_blog_naming_scheme
    ctx = make_context(current_path: "blog.html")

    assert_equal "/blog.html", ctx.blog_page_path(1)
    assert_equal "/blog-2.html", ctx.blog_page_path(2)
    assert_equal "/en/blog.html", ctx.blog_page_path(1, language: "en")
    assert_equal "/en/blog-2.html", ctx.blog_page_path(2, language: "en")
  end

  def test_blog_current_page_parses_paginated_paths
    assert_equal 1, make_context(current_path: "blog.html").blog_current_page
    assert_equal 3, make_context(current_path: "blog-3.html").blog_current_page
    assert_equal 1, make_context(current_path: "en/blog.html").blog_current_page
    assert_equal 4, make_context(current_path: "en/blog-4.html").blog_current_page
  end
end

require_relative "test_helper"

# Locks EVERY SEO entry of Site::View::Context against the behavior snapshot
# captured from master (test/fixtures/seo_snapshot.json, regenerated via
# test/scripts/extract_seo.rb).
#
# This is the regression net for the case/when -> data-table refactor: any
# 1:1 violation (title/description/keywords/schema params per path) fails
# here, and adding a new page without regenerating the fixture fails the
# completeness assertion below.
class SeoSnapshotTest < Minitest::Test
  FIXTURE_PATH = File.expand_path("fixtures/seo_snapshot.json", __dir__)

  def fixture
    @fixture ||= JSON.parse(File.read(FIXTURE_PATH))
  end

  def test_every_fixture_entry_matches_runtime_behavior
    mismatches = []

    fixture.each do |path, expected|
      ctx = make_context(current_path: path)

      actual_title = ctx.default_title_for_path(path)
      mismatches << "#{path.inspect} title" unless actual_title == expected["title"]

      actual_description = ctx.default_description_for_path(path)
      mismatches << "#{path.inspect} description" unless actual_description == expected["description"]

      actual_keywords = ctx.default_keywords_for_path(path)
      mismatches << "#{path.inspect} keywords" unless actual_keywords == expected["keywords"]

      schema_html = ctx.article_schema_for_current_path
      actual_schema = if schema_html.to_s.strip.empty?
                        nil
                      else
                        parsed = JSON.parse(schema_html[/\{.*\}/m])
                        {
                          "headline" => parsed["headline"],
                          "inLanguage" => parsed["inLanguage"],
                          "datePublished" => parsed["datePublished"],
                          "dateModified" => parsed["dateModified"],
                        }
                      end
      mismatches << "#{path.inspect} schema" unless actual_schema == expected["schema"]
    end

    assert_empty mismatches, "SEO behavior diverged from snapshot (#{mismatches.size}):\n#{mismatches.first(20).join("\n")}"
  end

  def test_fixture_covers_every_rendered_page
    generate_source = File.read(File.expand_path("../lib/site/generate.rb", __dir__))
    rendered_paths = generate_source.scan(/render export_dir, "([^"]+)"/).flatten

    (Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN).each do |post|
      rendered_paths << post[:url].sub(%r{\A/}, "")
    end

    uncovered = rendered_paths.uniq.reject { |path| fixture.key?(path) }

    assert_empty uncovered,
                 "pages not covered by the SEO snapshot — regenerate it with test/scripts/extract_seo.rb:\n#{uncovered.join("\n")}"
  end

  def test_nil_path_behaves_like_index
    ctx = make_context(current_path: nil)

    assert_equal ctx.default_title_for_path(""), ctx.default_title_for_path(nil)
  end
end

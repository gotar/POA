require_relative "test_helper"
require "cgi"
require "open3"

# Generic link text is fine visually, but a screen-reader link list needs the
# destination article named in every rendered blog card.
class BlogReadMoreAccessibilityTest < Minitest::Test
  BLOG_INDEX_GLOBS = {
    "blog*.html" => {
      prefix: "Czytaj więcej",
      visible_text: "Czytaj więcej →"
    },
    "en/blog*.html" => {
      prefix: "Read more",
      visible_text: "Read more →"
    }
  }.freeze

  def test_blog_read_more_links_name_their_article_in_each_language
    Dir.mktmpdir("poa-blog-read-more-links-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )

      assert status.success?, "expected build to pass:\n#{output}"

      BLOG_INDEX_GLOBS.each do |glob, expectations|
        paths = Dir[File.join(export_dir, glob)].sort
        refute_empty paths, "expected generated blog index pages matching #{glob}"

        paths.each do |path|
          assert_read_more_links_for_page(path, **expectations)
        end
      end
    end
  end

  def test_read_more_aria_label_is_localized_and_attribute_safe
    title = "A & B \"C\""

    assert_equal "Czytaj więcej: A &amp; B &quot;C&quot;", make_context(current_path: "blog.html").read_more_aria_label(title)
    assert_equal "Read more: A &amp; B &quot;C&quot;", make_context(current_path: "en/blog.html").read_more_aria_label(title)
  end

  private

  def assert_read_more_links_for_page(path, prefix:, visible_text:)
    cards = File.read(path).scan(%r{<article class="news-card">(.*?)</article>}m).flatten
    refute_empty cards, "#{path} must contain blog cards"

    cards.each do |card|
      heading = card.match(%r{<h2><a href="(?<href>[^"]+)">(?<title>.+?)</a></h2>}m)
      read_more = card.match(%r{<a class="news-read-more" href="(?<href>[^"]+)" aria-label="(?<label>[^"]+)">(?<text>[^<]+)</a>})

      refute_nil heading, "#{path} must expose each card title and destination"
      refute_nil read_more, "#{path} must give each read-more link an accessible article name"
      assert_equal heading[:href], read_more[:href], "#{path} read-more link must keep its article destination"
      assert_equal "#{prefix}: #{CGI.unescapeHTML(heading[:title])}", CGI.unescapeHTML(read_more[:label]), "#{path} read-more link must name its article"
      assert_equal visible_text, read_more[:text], "#{path} must preserve its localized visible link text"
    end
  end
end

require_relative "test_helper"

class MaaiArticleTest < Minitest::Test
  PAGES = %w[
    blog/ma-ai-dystans-ktory-decyduje.html
    en/blog/ma-ai-the-distance-that-decides.html
  ].freeze

  SOURCES = {
    "maai-source-1" => "https://aikidocenterla.com/blog/2021/9/9",
    "maai-source-2" => "https://aikidoyoshinkanottawa.ca/2021/12/21/ma-ai/",
    "maai-source-3" => "https://webspace.clarkson.edu/~lrussek/docs/Aikido/RussekAikidoInjuries.pdf"
  }.freeze

  def render_article(path)
    Site::Container["views.blog"]
    Site::Container["views.en.blog"]
    view = Site::Generate::PAGES.fetch(path)
    Site::Container[view].(context: make_context(current_path: path, root: site_root)).to_s
  end

  def test_both_languages_render_citations_with_resolvable_source_links
    PAGES.each do |path|
      html = render_article(path)
      SOURCES.each do |id, url|
        assert_includes html, %(href="##{id}"), "#{path}: missing inline citation"
        item = html[%r{<li id="#{id}">(.*?)</li>}m, 1]
        refute_nil item, "#{path}: missing source entry #{id}"
        assert_includes item, %(href="#{url}"), "#{path}: citation must lead to the named source"
      end
    end
  end

  def test_five_principle_link_points_to_a_registered_page_in_the_same_language
    PAGES.each do |path|
      target = if path.start_with?("en/")
        "en/blog/five-principles-behind-every-technique.html"
      else
        "blog/5-zasad-kazdej-techniki.html"
      end
      assert Site::Generate::PAGES.key?(target), "missing linked page #{target}"
      assert_includes render_article(path), %(href="/#{target}")
    end
  end
end

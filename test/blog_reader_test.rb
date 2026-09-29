require_relative "test_helper"
require "json"

# UIUX-06: shared blog reading template ("reader").
#
# All 96 PL/EN posts share one server-side hook (Context#blog_reader,
# applied from both layouts): visible author + read time, h2/h3 TOC
# with stable unique ids, and a language-aware footer. These tests pin
# behavior across the whole catalog — link targets must exist, ids
# must be unique, read time must follow the documented formula —
# not just selector presence.
class BlogReaderTest < Minitest::Test
  BLOG_PAGES = Site::Generate::PAGES.select { |path, _| path.match?(%r{\A(?:en/)?blog/.+\.html\z}) }.freeze

  def self.render_cache
    @render_cache ||= {}
  end

  # Resolving the index views first defines the Site::Views::Blog
  # namespace article views inherit from (same order as Generate#call).
  def self.warm_blog_namespace
    @warm_blog_namespace ||= begin
      Site::Container["views.blog"]
      Site::Container["views.en.blog"]
      true
    end
  end

  def render_blog(path)
    self.class.warm_blog_namespace
    self.class.render_cache[path] ||= begin
      view_key = BLOG_PAGES.fetch(path)
      ctx = make_context(current_path: path, root: site_root)
      Site::Container[view_key].(context: ctx).to_s
    end
  end

  def toc_block(html)
    html[%r{<details class="toc">.*?</details>}m]
  end

  def footer_block(html)
    html[%r{<nav class="article-reader-footer".*?</nav>}m]
  end

  def test_catalog_is_not_empty
    assert_operator BLOG_PAGES.size, :>=, 90, "expected the full PL/EN post catalog, got #{BLOG_PAGES.size}"
    pl = BLOG_PAGES.keys.count { |p| !p.start_with?("en/") }
    en = BLOG_PAGES.keys.count { |p| p.start_with?("en/") }
    assert_equal pl, en, "PL/EN post counts diverged (#{pl} vs #{en})"
  end

  def test_every_post_has_meta_with_schema_author_and_sane_read_time
    problems = []

    BLOG_PAGES.each_key do |path|
      html = render_blog(path)
      minutes = html[%r{<span class="article-reader-time">(\d+) min}, 1]&.to_i
      problems << "#{path}: author missing" unless html.include?(%(<span class="article-reader-author">#{Site::View::Context::BLOG_AUTHOR_NAME}</span>))
      if minutes.nil?
        problems << "#{path}: read time missing"
      elsif minutes < 1 || minutes > 60
        problems << "#{path}: implausible read time #{minutes} min"
      end
    end

    assert_empty problems, "reader metadata problems:\n#{problems.join("\n")}"
  end

  def test_visible_author_matches_article_schema_author
    %w[blog/mui-dzialanie-bez-wymuszania.html en/blog/mui-acting-without-forcing.html].each do |path|
      jsonld = JSON.parse(make_context(current_path: path).article_schema_for_current_path[/\{.*\}/m])
      assert_equal Site::View::Context::BLOG_AUTHOR_NAME, jsonld.dig("author", "name"),
        "#{path}: visible author must equal Article schema author.name"
    end
  end

  def test_toc_links_resolve_to_unique_heading_ids_on_every_post
    problems = []

    BLOG_PAGES.each_key do |path|
      html = render_blog(path)
      toc = toc_block(html)
      if toc.nil?
        problems << "#{path}: no TOC rendered"
        next
      end
      hrefs = toc.scan(/<a href="(#[^"]+)"/).flatten
      if hrefs.empty?
        problems << "#{path}: empty TOC link set"
        next
      end
      ids = html.scan(/ id="([^"]+)"/).flatten
      dupes = ids.tally.select { |_, n| n > 1 }.keys
      problems << "#{path}: duplicate ids #{dupes.first(3).join(", ")}" unless dupes.empty?
      hrefs.each do |href|
        id = href[1..]
        problems << "#{path}: TOC target ##{id} missing" unless ids.include?(id)
        unless html.match?(/<h[23] id="#{Regexp.escape(id)}" tabindex="-1">/)
          problems << "#{path}: ##{id} not a focusable heading"
        end
      end
      heading_count = html.scan(/<h[23] id="/).size
      problems << "#{path}: TOC links #{hrefs.size} != headings #{heading_count}" unless hrefs.size == heading_count
    end

    assert_empty problems, "TOC problems:\n#{problems.join("\n")}"
  end

  def test_reader_footer_links_stay_within_language
    problems = []

    BLOG_PAGES.each_key do |path|
      html = render_blog(path)
      footer = footer_block(html)
      if footer.nil?
        problems << "#{path}: no reader footer"
        next
      end
      hrefs = footer.scan(/href="([^"]+)"/).flatten
      if path.start_with?("en/")
        problems << "#{path}: EN footer links #{hrefs}" unless hrefs.sort == ["/en/blog.html", "/en/first-aikido-training-gdynia.html"].sort
      else
        problems << "#{path}: PL footer links #{hrefs}" unless hrefs.sort == ["/blog.html", "/pierwszy-trening-aikido-gdynia.html"].sort
      end
    end

    assert_empty problems, "footer language leaks:\n#{problems.join("\n")}"
  end

  def test_content_preserved_quotes_footnotes_kanji
    mui = render_blog("blog/mui-dzialanie-bez-wymuszania.html")
    assert_includes mui, "Przypisy i źródła", "sources section must survive the reader wrap"
    assert_includes mui, "無為", "kanji must survive the reader wrap"
    assert_match(%r{https://en\.wikipedia\.org/wiki/Wu_wei}, mui, "footnote links must survive")
    assert_match(%r{<ol>.*?</ol>}m, mui, "footnote list must survive")

    mui_en = render_blog("en/blog/mui-acting-without-forcing.html")
    assert_includes mui_en, "Notes and sources"
    assert_includes mui_en, "無為"

    ukemi = render_blog("blog/ukemi-bezpiecznie-upasc-zachowac-strukture-wrocic-do-dzialania.html")
    assert_includes ukemi, "Poza dojo ciało pamięta"
  end

  def test_non_article_pages_untouched
    { "blog.html" => "views.blog", "index.html" => "views.home", "en/blog.html" => "views.en.blog" }.each do |path, key|
      html = Site::Container[key].(context: make_context(current_path: path, root: site_root)).to_s
      refute_includes html, 'class="toc"', "#{path} must not get a reader TOC"
      refute_includes html, "article-reader-meta", "#{path} must not get reader metadata"
      refute_includes html, "article-reader-footer", "#{path} must not get a reader footer"
    end
  end

  def test_duplicate_headings_get_unique_ids_and_stable_toc
    ctx = make_context(current_path: "blog/mui-dzialanie-bez-wymuszania.html")
    raw = <<~HTML
      <div class="content"><div class="article">
      <p class="news-meta">28 września 2026</p>
      <h2>Wniosek</h2><p>a</p><h2>Wniosek</h2><p>b</p><h3>Wniosek</h3>
      </div></div>
    HTML

    once = ctx.blog_reader(raw)
    ids = once.scan(/<h[23] id="([^"]+)" tabindex="-1">/).flatten
    assert_equal %w[wniosek wniosek-2 wniosek-3], ids, "duplicate headings must not share an id"
    hrefs = toc_block(once).scan(/<a href="(#[^"]+)"/).flatten
    assert_equal %w[#wniosek #wniosek-2 #wniosek-3], hrefs

    # Re-rendering built output is a fixed point (ids preserved as-is).
    assert_equal once, ctx.blog_reader(once), "reader must be idempotent"
  end

  def test_existing_ids_preserved_and_empty_toc_state
    ctx = make_context(current_path: "en/blog/mui-acting-without-forcing.html")
    raw = <<~HTML
      <div class="content"><div class="article">
      <p class="news-meta">September 28, 2026</p>
      <h2 id="custom-anchor">Custom</h2>
      </div></div>
    HTML
    out = ctx.blog_reader(raw)
    assert_includes out, '<h2 id="custom-anchor" tabindex="-1">Custom</h2>'
    assert_includes toc_block(out), '<a href="#custom-anchor">Custom</a>'

    bare = ctx.blog_reader(<<~HTML)
      <div class="content"><div class="article">
      <p class="news-meta">September 28, 2026</p>
      <p>No sections here.</p>
      </div></div>
    HTML
    toc = toc_block(bare)
    assert_includes toc, "This article has no subsections."
    refute_includes toc, "toc-list", "empty TOC must not render a dead list"
  end

  def test_polish_diacritics_slugify_and_kanji_fallback
    ctx = make_context(current_path: "blog/mui-dzialanie-bez-wymuszania.html")
    assert_equal "zazolc-gesla-jazn", ctx.blog_slugify("Zażółć gęślą jaźń")
    assert_nil ctx.blog_slugify("無為自然"), "kanji-only headings have no latin slug"
    html, entries = ctx.blog_add_heading_ids("<h2>無為自然</h2>")
    assert_equal "sekcja", entries.first[:id]
    assert_includes html, 'id="sekcja"'
  end

  def test_reading_time_formula_and_sources_exclusion
    ctx = make_context(current_path: "blog/mui-dzialanie-bez-wymuszania.html")
    assert_equal 200, Site::View::Context::BLOG_READING_WPM, "reading speed constant is the documented contract"

    body = ("słowo " * 400).strip
    assert_equal 2, ctx.blog_reading_minutes("<p>#{body}</p>"), "400 words at 200wpm must read 2 min"

    short = ("słowo " * 600).strip
    long = ("słowo " * 601).strip
    assert_equal 3, ctx.blog_reading_minutes("<p>#{short}</p>")
    assert_equal 4, ctx.blog_reading_minutes("<p>#{long}</p>"), "read time must grow with real content"
    assert_equal 1, ctx.blog_reading_minutes("<p>cicho</p>"), "minimum is 1 minute"

    with_sources = "<p>#{body}</p><h2>Przypisy i źródła</h2><ol><li>#{body}</li></ol>"
    assert_equal 2, ctx.blog_reading_minutes(with_sources), "bibliography must not inflate read time"
    with_en_sources = "<p>#{body}</p><h2>References and sources</h2><ol><li>#{body}</li></ol>"
    assert_equal 2, ctx.blog_reading_minutes(with_en_sources)
  end

  def test_render_is_deterministic
    path = "blog/mui-dzialanie-bez-wymuszania.html"
    view_key = BLOG_PAGES.fetch(path)
    first = Site::Container[view_key].(context: make_context(current_path: path, root: site_root)).to_s
    second = Site::Container[view_key].(context: make_context(current_path: path, root: site_root)).to_s
    assert_equal first, second
  end

  def test_css_and_js_reader_contract
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
    assert_match(/\.article h2\[id\]/, css, "hash targets need scroll-margin-top under the sticky header")
    assert_match(/scroll-margin-top:\s*\d+px/, css)
    assert_match(/\.toc-summary:focus-visible/, css, "TOC disclosure needs a visible keyboard focus style")
    assert_match(/\.article-reader-footer/, css)

    js = File.read(site_root.join("assets/app.js"))
    assert_includes js, "initBlogToc", "TOC enhancement must be wired into initAll"
    assert_includes js, "details.toc", "enhancement must target the server-rendered disclosure"
    assert_includes js, "pushState", "TOC clicks must keep the hash for back/forward/deep-link"
    assert_includes js, "min-width: 769px", "desktop/mobile disclosure state needs the shared breakpoint"
  end
end

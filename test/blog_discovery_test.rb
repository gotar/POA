require_relative "test_helper"
require "json"
require "cgi"

# UIUX-08: blog discovery — beginner path, whole-catalog search
# contract, XSS-safe JSON embed, calm cards, no-JS baseline.
#
# The client-side matcher lives in assets/app.js (it cannot run in
# minitest); the identical contract is implemented server-side as
# Context#blog_fold_text / #blog_search_matches? / #blog_search_posts
# and pinned here behavior-first: a query must find a page-5 post,
# diacritics must fold, category+query must conjoin.
class BlogDiscoveryTest < Minitest::Test
  PL_BEGINNER_URLS = [
    "/blog/aikido-dla-nastolatkow.html",
    "/blog/dla-kogo-jest-aikido.html",
    "/blog/czy-warto-cwiczyc-aikido.html",
    "/blog/aikido-w-kazdym-wieku.html"
  ].freeze

  EN_BEGINNER_URLS = [
    "/en/blog/aikido-for-teenagers.html",
    "/en/blog/who-is-aikido-for.html",
    "/en/blog/is-aikido-worth-practicing.html",
    "/en/blog/aikido-at-every-age.html"
  ].freeze

  def test_fold_is_case_insensitive_and_strips_pl_diacritics
    ctx = make_context(current_path: "blog.html")
    assert_equal "hakame", ctx.blog_fold_text("Hakamę")
    assert_equal "hakame", ctx.blog_fold_text("HAKAMĘ")
    assert_equal "lodz", ctx.blog_fold_text("Łódź")
    assert_equal "zycie", ctx.blog_fold_text("Życie")
    assert_equal "gaman (我慢)", ctx.blog_fold_text("Gaman (我慢)")
    assert_equal "aiki", ctx.blog_fold_text("Áìkï")
  end

  def test_query_finds_article_from_last_pagination_page
    ctx = make_context(current_path: "blog.html")
    # Kuzushi is the final catalog entry (page 5 of 5): a full-index
    # query must reach it even though it shares the term with the
    # mui summary and the five-principles post.
    hits = ctx.blog_search_posts("kuzushi", nil, language: "pl")
    assert_includes hits.map { |h| h[:url] }, "/blog/kuzushi-kontrolowana-nierownowaga.html"
  end

  def test_query_matches_title_and_summary_with_diacritics_folding
    ctx = make_context(current_path: "blog.html")
    hits = ctx.blog_search_posts("hakame", nil, language: "pl")
    assert_includes hits.map { |h| h[:url] }, "/blog/dlaczego-w-aikido-nosi-sie-hakame.html"

    # Summary-only term (not in any title on the first page).
    summary_hits = ctx.blog_search_posts("napraw", nil, language: "pl")
    assert_includes summary_hits.map { |h| h[:url] }, "/blog/kintsugi-zlota-naprawa.html"
  end

  def test_category_and_query_conjoin
    ctx = make_context(current_path: "blog.html")
    both = ctx.blog_search_posts("hakame", "practice", language: "pl")
    assert_equal ["/blog/dlaczego-w-aikido-nosi-sie-hakame.html"], both.map { |h| h[:url] }

    wrong_cat = ctx.blog_search_posts("hakame", "philosophy", language: "pl")
    assert_empty wrong_cat

    cat_only = ctx.blog_search_posts("", "philosophy", language: "pl")
    expected = Site::View::Context::BLOG_POSTS_PL.count { |p| p[:category] == :philosophy }
    assert_equal expected, cat_only.size
    assert_operator cat_only.size, :>, 1
  end

  def test_empty_query_without_filter_returns_whole_catalog
    ctx = make_context(current_path: "blog.html")
    assert_equal Site::View::Context::BLOG_POSTS_PL.size,
      ctx.blog_search_posts("", nil, language: "pl").size
    assert_equal Site::View::Context::BLOG_POSTS_PL.size,
      ctx.blog_search_posts("  ", "all", language: "pl").size
    assert_equal Site::View::Context::BLOG_POSTS_EN.size,
      ctx.blog_search_posts("", nil, language: "en").size
  end

  def test_search_stays_within_language
    ctx = make_context(current_path: "blog.html")
    hits = ctx.blog_search_posts("kuzushi", nil, language: "en")
    assert_includes hits.map { |h| h[:url] }, "/en/blog/kuzushi-controlled-imbalance.html"
  end

  def test_safe_index_json_parses_to_full_catalog_and_cannot_break_script
    ctx = make_context(current_path: "blog.html")
    %w[pl en].each do |lang|
      raw = ctx.blog_index_json(language: lang)
      safe = ctx.blog_index_json_safe(language: lang)
      assert_equal JSON.parse(raw), JSON.parse(safe), "#{lang}: safe JSON must decode identically"
      refute_includes safe, "<", "#{lang}: safe JSON must not contain a raw <"
      refute_includes safe, ">", "#{lang}: safe JSON must not contain a raw >"
      refute_match(%r{</script}i, safe, "#{lang}: safe JSON must not close the script element")
      parsed = JSON.parse(safe)
      posts = lang == "en" ? Site::View::Context::BLOG_POSTS_EN : Site::View::Context::BLOG_POSTS_PL
      assert_equal posts.size, parsed.size, "#{lang}: embed must cover the whole catalog"
      assert_equal posts.map { |p| p[:url] }, parsed.map { |e| e["url"] }
    end
    assert_equal ctx.blog_index_json_safe(language: "pl"), ctx.blog_index_json_safe(language: "pl")
  end

  def test_page_one_renders_start_here_with_confirmed_beginner_posts
    {
      "blog.html" => ["views.blog", "pl", "Zacznij tutaj", PL_BEGINNER_URLS,
                       "Zapisy z praktyki i filozofii aikido"],
      "en/blog.html" => ["views.en.blog", "en", "Start here", EN_BEGINNER_URLS,
                          "Notes on aikido practice and philosophy"]
    }.each do |path, (view_key, lang, heading, urls, lead_fragment)|
      html = Site::Container[view_key].(context: make_context(current_path: path, root: site_root)).to_s
      assert_includes html, lead_fragment, "#{path}: lead must frame practice + philosophy"

      block = html[%r{<section class="blog-start-here".*?</section>}m]
      refute_nil block, "#{path}: start-here block must render on page 1"
      assert_includes block, %(<h2 id="blog-start-here-heading">#{heading}</h2>)
      hrefs = block.scan(/href="([^"]+)"/).flatten
      assert_equal urls, hrefs, "#{path}: start-here must link exactly the 4 confirmed beginner posts"

      article_pages = Site::Generate::PAGES.keys
      hrefs.each do |href|
        assert_includes article_pages, href.sub(%r{\A/}, ""), "#{path}: start-here #{href} must be a generated article"
        if lang == "pl"
          assert href.start_with?("/blog/"), "#{path}: start-here #{href} leaks across languages"
        else
          assert href.start_with?("/en/blog/"), "#{path}: start-here #{href} leaks across languages"
        end
      end
    end
  end

  def test_later_pages_have_no_start_here_but_keep_pagination_and_index
    html = Site::Container["views.blog"].(context: make_context(current_path: "blog-2.html", root: site_root)).to_s
    refute_includes html, "blog-start-here", "page 2 must not repeat the beginner block"
    assert_includes html, "Starsze wpisy (strona 2)."
    assert_match(%r{<nav class="pagination".*?</nav>}m, html, "page 2 must keep server pagination (no-JS)")
    assert_includes html, 'id="blog-index"', "page 2 must embed the whole-catalog index for search"
  end

  def test_cards_use_calm_titles_and_keep_category_and_read_more_contract
    html = Site::Container["views.blog"].(context: make_context(current_path: "blog.html", root: site_root)).to_s
    cards = html.scan(%r{<article class="news-card">(.*?)</article>}m).flatten
    assert_equal 10, cards.size
    cards.each do |card|
      assert_match(%r{<a class="news-card-title" href="[^"]+">[^<]+</a>}, card,
        "card titles must carry the calm-title class, not the red in-flow style")
      assert_match(%r{<p class="news-category">[^<]+</p>}, card, "card must keep its visible category (UIUX-07)")
      assert_match(%r{<a class="news-read-more" href="[^"]+" aria-label="[^"]+">}, card,
        "card must keep the accessible read-more link")
    end
  end

  def test_discovery_ui_is_js_built_so_no_js_keeps_plain_index
    %w[blog.html en/blog.html].each do |path|
      view_key = path.start_with?("en/") ? "views.en.blog" : "views.blog"
      html = Site::Container[view_key].(context: make_context(current_path: path, root: site_root)).to_s
      refute_includes html, "blog-search-form", "#{path}: no dead search form without JS"
      refute_includes html, "blog-category-pill", "#{path}: no dead filter buttons without JS"
      assert_includes html, '<nav class="pagination"', "#{path}: no-JS keeps full pagination"
    end
  end

  def test_client_discovery_wires_url_state_accessibility_and_safe_render
    js = File.read(site_root.join("assets/app.js"))
    %w[popstate pushState replaceState].each do |token|
      assert_includes js, token, "app.js must sync ?q=/cat= for reload/back/forward (#{token})"
    end
    assert_includes js, "aria-live", "result count must expose aria-live"
    assert_includes js, "setAttribute('role', 'status')", "result count must use the status role"
    assert_includes js, "aria-pressed", "category pills must expose pressed state"
    assert_includes js, "normalize('NFD')", "query folding must strip combining marks (diacritics)"
    assert_includes js, "replace(/ł/g, 'l')", "query folding must map ł explicitly (no NFD form)"
    assert_includes js, "textContent", "discovery must render via textContent (XSS-safe)"
    discovery = js[/function initBlogDiscovery\(\).*?\n  \}\n/m]
    refute_nil discovery, "expected the initBlogDiscovery module"
    refute_includes discovery, "innerHTML", "discovery must never inject HTML strings"
  end

  def test_css_covers_calm_cards_start_here_and_discovery_controls
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
    assert_match(/\.news-card-title/, css)
    assert_match(/\.blog-start-here/, css)
    assert_match(/\.blog-search-form/, css)
    assert_match(/\.blog-category-pill/, css)
    assert_match(/\.blog-result-count/, css)
    assert_match(/\.blog-empty/, css)

    %w[.blog-search-form\ input .blog-category-pill .blog-reset].each do |selector|
      blocks = css.scan(/#{Regexp.escape(selector)}[^{]*\{([^}]*)\}/m).flatten
      refute_empty blocks, "expected a #{selector} rule"
      assert blocks.any? { |b| b[/min-height:\s*44px/] }, "#{selector} must reach the 44px touch target"
    end

    assert_match(/\.news-list\[hidden\]/, css, "hidden server list must beat display:grid while filtering")
  end
end

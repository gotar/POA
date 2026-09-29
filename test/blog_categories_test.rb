require_relative "test_helper"
require "json"

# UIUX-07: closed blog category dictionary, translation-pair consistency,
# related-post rules, beginner path, full-catalog index, and visible
# category in the PL/EN blog UI. Behavior locks, not selector presence:
# related must resolve, prefer the same category, and stay in-language;
# the index must cover the whole catalog deterministically.
class BlogCategoriesTest < Minitest::Test
  EXPECTED_KEYS = %i[first_training practice technique philosophy dojo_life].freeze

  EXPECTED_LABELS = {
    first_training: { "pl" => "Pierwszy trening", "en" => "First training" },
    practice: { "pl" => "Praktyka", "en" => "Practice" },
    technique: { "pl" => "Technika", "en" => "Technique" },
    philosophy: { "pl" => "Filozofia", "en" => "Philosophy" },
    dojo_life: { "pl" => "Życie dojo", "en" => "Dojo life" }
  }.freeze

  def test_category_dictionary_is_closed_and_bilingual
    assert_equal EXPECTED_KEYS.sort, Site::View::Context::BLOG_CATEGORIES.keys.sort
    EXPECTED_LABELS.each do |key, labels|
      entry = Site::View::Context::BLOG_CATEGORIES.fetch(key)
      assert_equal labels["pl"], entry[:pl], "#{key}: PL label"
      assert_equal labels["en"], entry[:en], "#{key}: EN label"
    end
    pl = Site::View::Context::BLOG_CATEGORIES.values.map { |e| e[:pl] }
    en = Site::View::Context::BLOG_CATEGORIES.values.map { |e| e[:en] }
    assert_equal pl.uniq.size, pl.size, "PL labels must be distinct"
    assert_equal en.uniq.size, en.size, "EN labels must be distinct"
  end

  def test_every_post_carries_a_valid_category
    problems = []
    all_posts.each do |post|
      key = post[:category]
      problems << "#{post[:url]}: missing category" if key.nil?
      problems << "#{post[:url]}: unknown category #{key.inspect}" unless EXPECTED_KEYS.include?(key)
    end
    assert_empty problems, "posts without a valid category:\n#{problems.join("\n")}"
  end

  def test_every_category_has_members_in_both_languages
    %w[pl en].each do |lang|
      posts = lang == "en" ? Site::View::Context::BLOG_POSTS_EN : Site::View::Context::BLOG_POSTS_PL
      EXPECTED_KEYS.each do |key|
        count = posts.count { |p| p[:category] == key }
        assert_operator count, :>=, 1, "#{lang}: category #{key} is empty"
      end
    end
  end

  def test_translation_pairs_share_the_same_category_key
    problems = []
    Site::View::Context::LANG_URL_MAP.each do |pl_path, en_path|
      next unless pl_path.match?(%r{\Ablog/.+\.html\z})

      pl = Site::View::Context::BLOG_POSTS_PL.find { |p| p[:url] == "/#{pl_path}" }
      en = Site::View::Context::BLOG_POSTS_EN.find { |p| p[:url] == "/#{en_path}" }
      if pl.nil? || en.nil?
        problems << "#{pl_path} <-> #{en_path}: pair member missing from BLOG_POSTS"
      elsif pl[:category] != en[:category]
        problems << "#{pl_path} (#{pl[:category]}) <-> #{en_path} (#{en[:category]}): category diverged"
      end
    end
    assert_empty problems, "translation pair problems:\n#{problems.join("\n")}"
  end

  def test_no_duplicate_or_orphaned_post_urls
    %w[pl en].each do |lang|
      posts = lang == "en" ? Site::View::Context::BLOG_POSTS_EN : Site::View::Context::BLOG_POSTS_PL
      urls = posts.map { |p| p[:url] }
      dupes = urls.tally.select { |_, n| n > 1 }.keys
      assert_empty dupes, "#{lang}: duplicate post URLs: #{dupes}"
    end

    article_pages = Site::Generate::PAGES.keys.select { |p| p.match?(%r{\A(?:en/)?blog/.+\.html\z}) }
    orphans = all_posts.reject { |p| article_pages.include?(p[:url].sub(%r{\A/}, "")) }
    assert_empty orphans.map { |p| p[:url] }, "posts with no generated article page (orphaned URLs)"
  end

  def test_related_never_self_never_cross_language_always_resolves
    problems = []
    {
      "pl" => Site::View::Context::BLOG_POSTS_PL,
      "en" => Site::View::Context::BLOG_POSTS_EN
    }.each do |lang, posts|
      urls = posts.map { |p| p[:url] }
      posts.each do |post|
        related = make_context(current_path: "blog.html").blog_related_posts(post[:url], language: lang)
        assert_operator related.size, :<=, Site::View::Context::BLOG_RELATED_LIMIT
        related.each do |rel|
          problems << "#{post[:url]}: related points to itself" if rel[:url] == post[:url]
          problems << "#{post[:url]}: related #{rel[:url]} not in #{lang} catalog" unless urls.include?(rel[:url])
        end
        # Same-category preference: when the category has other members,
        # the first suggestion must come from it.
        mates = posts.count { |p| p[:category] == post[:category] } - 1
        if mates.positive? && !related.empty? && related.first[:category] != post[:category]
          problems << "#{post[:url]}: first related #{related.first[:url]} ignores same category #{post[:category]}"
        end
      end
    end
    assert_empty problems, "related-post problems:\n#{problems.first(20).join("\n")}"
  end

  def test_related_is_deterministic_and_unknown_path_yields_nothing
    ctx = make_context(current_path: "blog.html")
    sample = Site::View::Context::BLOG_POSTS_PL.first[:url]
    first = ctx.blog_related_posts(sample, language: "pl")
    second = ctx.blog_related_posts(sample, language: "pl")
    assert_equal first, second
    assert_empty ctx.blog_related_posts("/blog/nie-istnieje.html", language: "pl")
    assert_equal "", ctx.blog_related_html("pl", "/blog/nie-istnieje.html")
  end

  def test_index_covers_the_whole_catalog_and_is_deterministic
    ctx = make_context(current_path: "blog.html")
    {
      "pl" => Site::View::Context::BLOG_POSTS_PL,
      "en" => Site::View::Context::BLOG_POSTS_EN
    }.each do |lang, posts|
      index = ctx.blog_index(language: lang)
      assert_equal posts.size, index.size, "#{lang}: index must cover every post (all pagination pages)"
      assert_equal posts.map { |p| p[:url] }, index.map { |i| i[:url] }, "#{lang}: index order must follow the catalog"
      index.each do |entry|
        assert EXPECTED_KEYS.include?(entry[:category]), "#{entry[:url]}: bad index category"
        assert_equal EXPECTED_LABELS.fetch(entry[:category])[lang], entry[:category_label]
      end
      parsed = JSON.parse(ctx.blog_index_json(language: lang))
      assert_equal index.size, parsed.size
      assert_equal index.map { |i| i[:url] }, parsed.map { |e| e["url"] }
      assert_equal ctx.blog_index_json(language: lang), ctx.blog_index_json(language: lang)
    end
  end

  def test_beginner_path_is_the_first_training_category_in_catalog_order
    ctx = make_context(current_path: "blog.html")
    {
      "pl" => Site::View::Context::BLOG_POSTS_PL,
      "en" => Site::View::Context::BLOG_POSTS_EN
    }.each do |lang, posts|
      featured = ctx.blog_featured_posts(language: lang)
      expected = posts.select { |p| p[:category] == :first_training }
      refute_empty featured, "#{lang}: beginner path must not be empty"
      assert_equal expected.map { |p| p[:url] }, featured.map { |p| p[:url] }
    end
    pl_urls = ctx.blog_featured_posts(language: "pl").map { |p| p[:url] }
    assert_includes pl_urls, "/blog/dla-kogo-jest-aikido.html"
    assert_includes pl_urls, "/blog/czy-warto-cwiczyc-aikido.html"
  end

  def test_category_visible_in_blog_index_ui_both_languages
    {
      "blog.html" => ["views.blog", "pl", Site::View::Context::BLOG_POSTS_PL],
      "en/blog.html" => ["views.en.blog", "en", Site::View::Context::BLOG_POSTS_EN]
    }.each do |path, (view_key, lang, posts)|
      html = Site::Container[view_key].(context: make_context(current_path: path, root: site_root)).to_s
      cards = html.scan(%r{<article class="news-card">.*?</article>}m)
      assert_equal 10, cards.size, "#{path}: first index page must list 10 cards"
      cards.each_with_index do |card, i|
        label = EXPECTED_LABELS.fetch(posts[i][:category])[lang]
        assert_includes card, %(<p class="news-category">#{label}</p>), "#{path} card #{i} (#{posts[i][:url]}) must show its category"
      end
    end
  end

  def test_reader_shows_category_and_related_but_keeps_footer_contract
    # Article views inherit from the Site::Views::Blog namespace, which
    # only exists after the index views resolve (same order as Generate).
    Site::Container["views.blog"]
    Site::Container["views.en.blog"]
    {
      "blog/mui-dzialanie-bez-wymuszania.html" => ["pl", "Filozofia", "Powiązane wpisy", ["/blog.html", "/pierwszy-trening-aikido-gdynia.html"]],
      "en/blog/mui-acting-without-forcing.html" => ["en", "Philosophy", "Related posts", ["/en/blog.html", "/en/first-aikido-training-gdynia.html"]]
    }.each do |path, (lang, label, heading, footer_hrefs)|
      view_key = Site::Generate::PAGES.fetch(path)
      html = Site::Container[view_key].(context: make_context(current_path: path, root: site_root)).to_s
      assert_includes html, %(<span class="article-reader-category">#{label}</span>), "#{path}: reader meta must carry the category"
      assert_includes html, heading, "#{path}: related block must render"
      nav = html[%r{<nav class="article-reader-related".*?</nav>}m]
      refute_nil nav, "#{path}: related nav missing"
      hrefs = nav.scan(/href="([^"]+)"/).flatten
      assert_equal 3, hrefs.size, "#{path}: related must offer 3 posts"
      refute_includes hrefs, "/#{path}", "#{path}: related must not link to itself"
      hrefs.each do |href|
        if lang == "pl"
          assert href.start_with?("/blog/"), "#{path}: related #{href} leaks across languages"
        else
          assert href.start_with?("/en/blog/"), "#{path}: related #{href} leaks across languages"
        end
      end
      footer = html[%r{<nav class="article-reader-footer".*?</nav>}m]
      refute_nil footer, "#{path}: reader footer missing"
      assert_equal footer_hrefs.sort, footer.scan(/href="([^"]+)"/).flatten.sort, "#{path}: footer contract (UIUX-06) must stay intact"
    end
  end

  def test_css_covers_new_blog_elements
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
    assert_match(/\.news-category/, css)
    assert_match(/\.article-reader-category/, css)
    assert_match(/\.article-reader-related/, css)
  end

  private

  def all_posts
    Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN
  end
end

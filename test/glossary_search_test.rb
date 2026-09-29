require_relative "test_helper"

# UIUX-12: glossary search — short H1, category anchors, in-place
# row filtering contract, no-JS baseline.
#
# The client-side matcher lives in assets/app.js (it cannot run in
# minitest); the identical fold contract is Context#blog_fold_text
# (pinned in test/blog_discovery_test.rb) and the row-level behavior
# is pinned here against the real rendered tables: a query must find
# rows across the whole page (head and tail sections), diacritics and
# kanji must match, an unknown query must match nothing.
class GlossarySearchTest < Minitest::Test
  PL_PATH = "slowniczek.html"
  EN_PATH = "en/glossary.html"

  def render_glossary(path)
    key = path.start_with?("en/") ? "views.en.glossary" : "views.glossary"
    Site::Container[key].(context: make_context(current_path: path, root: site_root)).to_s
  end

  def table_rows(html)
    html.scan(%r{<tr>(.*?)</tr>}m).flatten
  end

  def row_text(row_html)
    row_html.gsub(%r{<[^>]+>}, " ")
  end

  def matching_rows(html, query)
    ctx = make_context(current_path: PL_PATH)
    folded = ctx.blog_fold_text(query).strip
    return [] if folded.empty?

    table_rows(html).select do |row|
      ctx.blog_fold_text(row_text(row)).include?(folded)
    end
  end

  def test_short_h1_with_scope_lead_and_unchanged_seo_title
    {
      PL_PATH => ["Słowniczek aikido",
                  "Slowniczek Aikido | Terminy Japonskie | POA",
                  "terminy japońskie z polskimi tłumaczeniami"],
      EN_PATH => ["Aikido glossary",
                  "Aikido Glossary | Japanese Terms | POA",
                  "Japanese terms with English translations"]
    }.each do |path, (h1, title, lead_fragment)|
      html = render_glossary(path)
      assert_equal 1, html.scan(/<h1[^>]*>/).size, "#{path}: exactly one h1"
      assert_includes html, "<h1>#{h1}</h1>", "#{path}: h1 must be short"
      assert_includes html, lead_fragment, "#{path}: scope description must sit outside the h1"
      assert_includes html, "<title>#{title} | Polska Organizacja Aikido</title>",
                      "#{path}: new h1 must not change the SEO title/canonical contract"
    end
  end

  def test_category_nav_links_match_section_ids_with_en_parity
    pl = render_glossary(PL_PATH)
    en = render_glossary(EN_PATH)

    [pl, en].each do |html|
      nav = html[%r{<nav class="glossary-categories".*?</nav>}m]
      refute_nil nav, "category shortcut nav must render"
      links = nav.scan(/href="(#[^"]+)"/).flatten
      ids = html.scan(/<h2 id="([^"]+)">/).flatten
      assert_equal 17, links.size, "nav must shortcut all 17 existing categories"
      assert_equal 17, ids.size, "every section heading needs an anchor id"
      assert_equal ids.map { |id| "##{id}" }.sort, links.sort,
                   "every nav link must resolve to a section, no orphans either way"
    end

    pl_ids = pl.scan(/<h2 id="([^"]+)">/).flatten
    en_ids = en.scan(/<h2 id="([^"]+)">/).flatten
    assert_equal pl_ids.size, en_ids.size, "EN must keep category parity with PL"
  end

  def test_all_terms_illustrations_and_no_js_full_dictionary
    {
      PL_PATH => ["Ukemi (受け身)", "Takemusu Aiki (武産合気)", "Kototama (言霊)",
                  "Shintai", "Aikido (合気道)"],
      EN_PATH => ["Ukemi (受け身)", "Kototama (言霊)", "Aikido (合気道)"]
    }.each do |path, terms|
      html = render_glossary(path)
      assert_equal 162, table_rows(html).size, "#{path}: all 162 terms must survive"
      terms.each do |term|
        assert_includes html, term, "#{path}: term #{term} must survive"
      end
      refute_match(/<(tr|h2|div class="glossary-section")[^>]*\bhidden\b/, html,
                   "#{path}: no-JS must show the whole dictionary (no hidden rows/sections)")
      refute_includes html, "glossary-search-form", "#{path}: no dead search form without JS"
      assert_includes html, "data-glossary-search-mount", "#{path}: JS search mount must exist"
      assert_includes html, 'class="glossary-categories"', "#{path}: anchors must work without JS"
    end

    pl = render_glossary(PL_PATH)
    assert_includes pl, "/assets/images/glossary/cialo.jpg"
    assert_includes pl, "/assets/images/glossary/numbers.png"
    assert_includes pl, "/assets/images/glossary/cnoty.jpg"
  end

  def test_query_finds_head_and_tail_terms_with_folded_diacritics_and_kanji
    pl = render_glossary(PL_PATH)

    # Ukemi rows live mid-page; the query must reach all of them.
    ukemi = matching_rows(pl, "ukemi")
    assert_operator ukemi.size, :>=, 3, "ukemi must match Ukemi + Yoko/Mae Ukemi"

    # Tail-section term (last category): the search covers the whole page.
    assert_operator matching_rows(pl, "kototama").size, :>=, 1,
                    "a term from the final section must be found"

    # Kanji query matches the romaji+kanji term cells.
    assert_operator matching_rows(pl, "合気道").size, :>=, 1, "kanji query must match"

    # Polish letters fold: plain and diacritic spellings agree.
    assert_equal matching_rows(pl, "głowa").size, matching_rows(pl, "glowa").size
    assert_operator matching_rows(pl, "głowa").size, :>, 1, "diacritics must fold"

    # Case-insensitive.
    assert_equal matching_rows(pl, "UKEMI").size, ukemi.size

    # Unknown query matches nothing (empty state path).
    assert_empty matching_rows(pl, "xyzqwerty")

    en = render_glossary(EN_PATH)
    assert_operator matching_rows(en, "ukemi").size, :>=, 3, "EN parity for ukemi"
    assert_operator matching_rows(en, "kototama").size, :>=, 1, "EN parity for the tail term"
    assert_empty matching_rows(en, "xyzqwerty")
  end

  def test_client_search_wires_url_state_accessibility_and_safe_render
    js = File.read(site_root.join("assets/app.js"))
    assert_includes js, "initGlossarySearch()", "glossary search must run in initAll"
    %w[popstate pushState replaceState].each do |token|
      assert_includes js, token, "app.js must sync ?q= for reload/back/forward (#{token})"
    end
    assert_includes js, "aria-live", "result count must expose aria-live"
    assert_includes js, "setAttribute('role', 'status')", "result count must use the status role"
    assert_includes js, "glossary-search-mount", "search UI must mount on the server-rendered slot"
    assert_includes js, "glossary-categories", "category shortcuts must pair with sections"
    assert_includes js, "blogFoldText(", "query folding must reuse the pinned PL/EN fold (diacritics)"
    assert_includes js, "textContent", "search must build UI via textContent (XSS-safe)"

    mod = js[/function initGlossarySearch\(\).*?\n  \}\n/m]
    refute_nil mod, "expected the initGlossarySearch module"
    refute_includes mod, "innerHTML", "search must never inject HTML strings (unknown query = no XSS)"
    assert_includes mod, ".hidden =", "filtering must hide rows/sections in place (no re-render)"
  end

  def test_css_covers_search_categories_count_and_hidden_sections
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
    %w[.glossary-lead .glossary-search .glossary-search-form .glossary-categories
       .glossary-result-count .glossary-reset .glossary-empty].each do |selector|
      assert_match(/#{Regexp.escape(selector)}/, css, "expected a #{selector} rule")
    end

    ['.glossary-search-form input[type="search"]', ".glossary-categories a", ".glossary-reset"].each do |selector|
      blocks = css.scan(/#{Regexp.escape(selector)}[^{]*\{([^}]*)\}/m).flatten
      refute_empty blocks, "expected a #{selector} rule"
      assert blocks.any? { |b| b[/min-height:\s*44px/] }, "#{selector} must reach the 44px touch target"
    end

    assert_match(/\.glossary-section\[hidden\]/, css,
                 "hidden sections must beat display:flex while filtering")
    assert_match(/\.content h2\[id\][^{]*\{[^}]*scroll-margin-top/, css,
                 "anchored headings must clear the sticky header")
  end
end

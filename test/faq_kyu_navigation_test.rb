require_relative "test_helper"

# UIUX-13: FAQ + kyu quick navigation — every question and every grade
# reachable by keyboard without scrolling the whole page; anchors and
# focus targets server-rendered (no-JS safe); content and technique
# order unchanged; JSON-LD stays consistent with visible answers.
#
# The client-side hash/focus/aria-current enhancement lives in
# assets/app.js (it cannot run in minitest); the contract pinned here
# is the server-rendered baseline it enhances: anchor ids, TOC/index
# links that all resolve, focusable targets, preserved wording.
class FaqKyuNavigationTest < Minitest::Test
  PL_FAQ_QUESTIONS = [
    "Czym jest Aikido?",
    "Czy Aikido to dobra szkoła samoobrony?",
    "Od jakiego wieku można zacząć trenować Aikido?",
    "Czy muszę być sprawny fizycznie, żeby zacząć?",
    "Jak często powinienem trenować?",
    "Co powinienem zabrać na pierwsze zajęcia?",
    "Czy w Aikido są zawody sportowe lub sparingi?",
    "Jak długo trwa nauka Aikido?",
    "Gdzie odbywają się treningi Aikido w Gdyni?",
    "O której godzinie są zajęcia w Gdyni?",
    "Ile kosztuje trening Aikido w Gdyni?",
    "Kto prowadzi zajęcia w Sesshinkan Dojo Gdynia?",
    "Czy w Aikido są kolorowe pasy?",
    "Co to jest hakama?",
    "Czy w Aikido używa się broni?",
    "Jak wyglądają egzaminy na stopnie w Aikido?",
    "Co to jest POA - Polska Organizacja Aikido?",
    "Czy moje stopnie będą uznawane za granicą?"
  ].freeze

  EN_FAQ_QUESTIONS = [
    "What is Aikido?",
    "Is Aikido effective for self-defense?",
    "What age can I start training Aikido?",
    "Do I need to be physically fit to start?",
    "How often should I train?",
    "What should I bring to my first class?",
    "Are there competitions or sparring in Aikido?",
    "How long does it take to learn Aikido?",
    "Where are Aikido classes held in Gdynia?",
    "What time are classes in Gdynia?",
    "How much does Aikido training cost in Gdynia?",
    "Who leads classes at Sesshinkan Dojo Gdynia?",
    "Are there colored belts in Aikido?",
    "What is hakama?",
    "Is weapon training used in Aikido?",
    "What do examinations for degrees look like in Aikido?",
    "What is POA - Polish Aikido Organization?",
    "Will my degrees be recognized abroad?"
  ].freeze

  PL_KYU_NOTES = [
    "Są to wymagania minimalne i komisja może zażyczyć sobie wykonania dodatkowych technik czy wersji.",
    "Wiele z powyższych technik ma wersji omote (z przodu) i ura (z tyłu). Demonstracja obu wersji jest wymagana.",
    "Wiele z technik ma wersje statyczne i dynamiczne które trzeba znać.",
    "są wersjami wymaganymi bezwzględnie",
    "Wymagania egzaminacyjne się kumulują (zdając na kolejny stopień musisz znać materiał z poprzednich).",
    "Egzamin przeprowadza Sensei ze stopniem minimum 3 dan. Stopnie od 5 kyu zdajemy przed komisją (na seminariach i obozach)."
  ].freeze

  EN_KYU_NOTES = [
    "These are minimum requirements and the examination committee may request additional techniques or variations.",
    "Many of the above techniques have omote (front) and ura (back) versions. Both versions must be demonstrated.",
    "Many techniques have static and dynamic versions which must be known.",
    "versions are absolutely required",
    "Exam requirements are cumulative (when advancing to the next grade, you must know material from previous grades).",
    "Exams are conducted by a Sensei with a minimum rank of 3 dan. Grades from 5 kyu are taken before a committee (at seminars and camps)."
  ].freeze

  def render_view(key, path)
    Site::Container[key].(context: make_context(current_path: path, root: site_root)).to_s
  end

  def test_faq_every_question_anchorable_with_full_index_pl_en
    {
      ["views.faq", "faq.html", PL_FAQ_QUESTIONS, "spis-tresci"] => "PL",
      ["views.en.faq", "en/faq.html", EN_FAQ_QUESTIONS, "table-of-contents"] => "EN"
    }.each do |(key, path, questions, toc_id), lang|
      html = render_view(key, path)

      items = html.scan(%r{<div class="faq-item" id="([^"]+)"[^>]*tabindex="-1">}).flatten
      assert_equal 18, items.size, "#{lang}: all 18 answers need an anchor id + focus target"
      assert_equal items.uniq.size, items.size, "#{lang}: question ids must be unique"

      nav = html[%r{<nav class="faq-toc" id="#{toc_id}".*?</nav>}m]
      refute_nil nav, "#{lang}: question index nav must render"
      links = nav.scan(/href="(#[^"]+)"/).flatten
      assert_equal 23, links.size, "#{lang}: index must link 5 sections + 18 questions"

      ids = html.scan(/ id="([^"]+)"/).flatten
      links.each do |href|
        assert_includes ids, href[1..], "#{lang}: index link #{href} must resolve to an id"
      end

      headings = html.scan(%r{<h3 itemprop="name">([^<]+)</h3>}).flatten
      assert_equal questions, headings, "#{lang}: question wording and order must be unchanged"

      item_heading_ids = html.scan(
        %r{<div class="faq-item" id="([^"]+)"[^>]*>\s*<h3 itemprop="name">([^<]+)</h3>}m
      )
      assert_equal questions.size, item_heading_ids.size, "#{lang}: every item pairs one id with one heading"
      item_heading_ids.each do |id, heading|
        assert_includes links, "##{id}", "#{lang}: item ##{id} must be reachable from the index"
        assert_includes questions, heading, "#{lang}: item heading must be a known question"
      end

      section_ids = html.scan(%r{<h2 id="([^"]+)" tabindex="-1">}).flatten
      assert_operator section_ids.size, :>=, 5, "#{lang}: section headings need focusable anchors"
      (section_ids.map { |id| "##{id}" } - links).tap do |orphans|
        assert_empty orphans, "#{lang}: every section must be linked from the index"
      end

      assert_equal 5, html.scan(/class="faq-back"/).size,
                   "#{lang}: every section end needs a return-to-index link"
    end
  end

  # The PL page carries an FAQPage schema for its Gdynia questions; the EN
  # page ships no FAQ schema (pre-existing state, kept as-is). The pin
  # below guards that the schema stays consistent with the visible full
  # answers it claims to describe.
  def test_faq_json_ld_matches_visible_answers
    html = render_view("views.faq", "faq.html")

    scripts = html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten
    refute_empty scripts, "PL: FAQ page must render JSON-LD scripts"
    faq = scripts.map { |s| JSON.parse(s) }.find { |j| j["@type"] == "FAQPage" }
    refute_nil faq, "PL: an FAQPage schema must render"

    names = faq["mainEntity"].map { |q| q["name"] }
    refute_empty names, "PL: FAQ schema must carry questions"
    names.each do |name|
      assert_includes PL_FAQ_QUESTIONS, name,
                      "PL: schema question must match a visible full answer"
    end
  end

  def test_kyu_grade_index_notes_and_returns_pl_en
    {
      ["views.requirement_kyu", "wymagania_egzaminacyjne/kyu.html",
       PL_KYU_NOTES, "indeks-stopni", "Ważne informacje"] => "PL",
      ["views.en.requirement_kyu", "en/requirements/kyu.html",
       EN_KYU_NOTES, "grade-index", "Important Information"] => "EN"
    }.each do |(key, path, notes, index_id, notes_heading), lang|
      html = render_view(key, path)

      nav = html[%r{<nav class="kyu-index" id="#{index_id}".*?</nav>}m]
      refute_nil nav, "#{lang}: grade index nav must render"
      links = nav.scan(/href="(#[^"]+)"/).flatten
      assert_equal %w[#7kyu #6kyu #5kyu #4kyu #3kyu #2kyu #1kyu].sort, links.sort,
                   "#{lang}: index must shortcut grades 7..1, nothing added or dropped"

      grades = html.scan(%r{<h2 id="([1234567]kyu)" tabindex="-1">}).flatten
      assert_equal %w[7kyu 6kyu 5kyu 4kyu 3kyu 2kyu 1kyu].sort, grades.sort,
                   "#{lang}: all seven grade sections need focusable anchors"

      assert_includes html, "<h3 id=\"#{lang == "PL" ? "uwagi" : "notes"}\">#{notes_heading}</h3>",
                      "#{lang}: notes heading keeps its wording with an anchor"
      notes.each do |note|
        assert_includes html, note, "#{lang}: note wording must be unchanged"
      end

      assert_equal 7, html.scan(/class="kyu-back"/).size,
                   "#{lang}: every grade section needs a return-to-index link"
    end
  end

  def test_no_js_baseline_content_and_targets_in_raw_templates
    {
      "templates/faq.html.erb" => 18,
      "templates/faq_en.html.erb" => 18
    }.each do |template, count|
      raw = File.read(site_root.join(template))
      assert_equal count, raw.scan(/class="faq-item" id="/).size,
                   "#{template}: anchors must be server-rendered, not JS-injected"
    end
  end

  def test_css_scroll_margin_touch_targets_and_target_tint
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    assert_match(/\.faq-item\[id\][^{]*\{[^}]*scroll-margin-top:\s*96px/m, css,
                 "questions must not hide under the sticky header on deep links")
    assert_match(/\.content h2\[id\][^{]*\{[^}]*scroll-margin-top:\s*96px/m, css,
                 "grade/section headings must not hide under the sticky header")
    assert_match(/\.faq-item\[id\]:target\s*\{[^}]*border-left-color:\s*#cd3333/m, css,
                 "the linked question must show a visible :target location")

    inline = css[/ul\.inline li a \{(?<rules>[^}]*)\}/m, :rules]
    refute_nil inline, "expected a ul.inline li a rule"
    assert_match(/min-height:\s*44px/, inline, "grade shortcuts must be touch-sized")

    toc_links = css[/\.faq-toc > ul > li > ul a \{(?<rules>[^}]*)\}/m, :rules]
    refute_nil toc_links, "expected a nested FAQ index link rule"
    assert_match(/min-height:\s*44px/, toc_links, "question shortcuts must be touch-sized")
  end

  def test_js_nav_enhancement_registered
    js = File.read(site_root.join("assets/app.js"))
    assert_includes js, "function initFaqKyuNav()",
                    "app.js must define the FAQ/kyu hash+focus+spy enhancement"
    assert_includes js, "initFaqKyuNav();",
                    "the enhancement must run with the other initializers"
    assert_includes js, "aria-current",
                    "the visible section must be exposed to assistive tech"
    assert_includes js, "getElementById",
                    "grade ids like 7kyu are not valid CSS selectors, lookup must not throw"
  end
end

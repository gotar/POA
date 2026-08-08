require_relative "test_helper"

# Behavior locks for Site::View::Context#page_title edge cases and the SEO
# lookup plumbing. The SEO data itself (every title/description/keywords
# entry) is locked by the fixture test (test/seo_snapshot_test.rb).
class ContextPageTitleTest < Minitest::Test
  def test_title_without_site_name_gets_joined_with_separator
    ctx = make_context(page_title: "Czym jest Aikido?", settings: settings(site_name: "Polska Organizacja Aikido"))

    assert_equal "Czym jest Aikido? | Polska Organizacja Aikido", ctx.page_title
  end

  def test_title_already_containing_site_name_is_not_duplicated
    ctx = make_context(page_title: "Polska Organizacja Aikido — treningi", settings: settings(site_name: "Polska Organizacja Aikido"))

    assert_equal "Polska Organizacja Aikido — treningi", ctx.page_title
  end

  def test_title_containing_site_name_case_insensitively_is_not_duplicated
    ctx = make_context(page_title: "polska organizacja aikido — treningi", settings: settings(site_name: "Polska Organizacja Aikido"))

    assert_equal "polska organizacja aikido — treningi", ctx.page_title
  end

  def test_empty_site_name_returns_title_alone
    ctx = make_context(page_title: "Treningi Aikido w Gdyni", settings: settings(site_name: ""))

    assert_equal "Treningi Aikido w Gdyni", ctx.page_title
  end

  def test_nil_site_name_returns_title_alone
    ctx = make_context(page_title: "Treningi Aikido w Gdyni", settings: settings(site_name: nil))

    assert_equal "Treningi Aikido w Gdyni", ctx.page_title
  end

  def test_nil_page_title_uses_default_title_for_path
    ctx = make_context(page_title: nil, current_path: "kontakt.html")

    assert_equal "Kontakt i grafik treningów Aikido | Gdynia | Sesshinkan Dojo | Polska Organizacja Aikido", ctx.page_title
    assert_equal "Kontakt i grafik treningów Aikido | Gdynia | Sesshinkan Dojo", ctx.default_title_for_path("kontakt.html")
  end

  def test_nil_default_title_falls_back_to_site_name
    ctx = make_context(current_path: "x.html")
    ctx.define_singleton_method(:default_title_for_path) { |_path| nil }

    assert_equal "Polska Organizacja Aikido", ctx.page_title
  end

  def test_blank_title_falls_back_to_site_name
    ctx = make_context(page_title: "   ", settings: settings(site_name: "Polska Organizacja Aikido"))

    assert_equal "Polska Organizacja Aikido", ctx.page_title
  end

  def test_default_title_for_unknown_path_falls_back_to_site_name
    ctx = make_context(current_path: "strona-ktorej-nie-ma.html")

    assert_equal "Polska Organizacja Aikido", ctx.default_title_for_path("strona-ktorej-nie-ma.html")
  end
end

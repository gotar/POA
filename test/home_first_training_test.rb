require_relative "test_helper"
require "open3"

# UIUX-09: home leads to the first training (PL/EN).
#
# Order: short hero -> schedule/location/free trial -> who/how ->
# instructor/school -> key FAQ -> selected posts -> contact.
# Max 3 start choices; legacy near-duplicate tiles and repeated bottom
# link lists are gone (URLs themselves still render — see InternalLinksTest
# known_pages / generator PAGES, not this file).
class HomeFirstTrainingTest < Minitest::Test
  PL_HOME = "templates/home.html.erb"
  EN_HOME = "templates/home_en.html.erb"

  def pl_template
    File.read(site_root.join(PL_HOME))
  end

  def en_template
    File.read(site_root.join(EN_HOME))
  end

  def quick_nav_block(template)
    template[/<div class="quick-nav">.*?<\/div>\s*<div class="home-section">/m] || template[/<div class="quick-nav">.*/m] || ""
  end

  def test_hero_leads_with_first_training_cta
    assert_includes pl_template, 'class="hero-btn primary" href="/pierwszy-trening-aikido-gdynia.html"'
    assert_includes pl_template, "Przyjdź na pierwszy trening"
    assert_includes pl_template, 'href="/gdynia.html">Grafik i dojazd'

    assert_includes en_template, 'class="hero-btn primary" href="/en/first-aikido-training-gdynia.html"'
    assert_includes en_template, "Come to your first training"
    assert_includes en_template, 'href="/en/gdynia.html"'
  end

  def test_hero_keeps_seasonal_intake_and_lineage_contract
    # SeasonalIntakeTest owns the full contract; pin the strings here so a
    # future hero rewrite cannot silently drop them.
    assert_match(/<p class="hero-description">.*Nowy sezon.*przez cały rok.*<\/p>/m, pl_template)
    assert_includes pl_template, "Fumio Toyod"
    assert_match(/<p class="hero-description">.*new season.*throughout the year.*<\/p>/m, en_template)
    assert_includes en_template, "Fumio Toyod"
  end

  def test_max_three_start_choices_with_existing_targets
    assert_equal 3, pl_template.scan('class="quick-nav-item"').length, "PL home must offer exactly 3 start choices"
    assert_equal 3, en_template.scan('class="quick-nav-item"').length, "EN home must offer exactly 3 start choices"

    %w[
      /pierwszy-trening-aikido-gdynia.html
      /gdynia.html
      /aikido/dla_poczatkujacych.html
    ].each { |href| assert_includes pl_template, "href=\"#{href}\"" }

    %w[
      /en/first-aikido-training-gdynia.html
      /en/gdynia.html
      /en/aikido/beginners.html
    ].each { |href| assert_includes en_template, "href=\"#{href}\"" }
  end

  def test_legacy_duplicate_tiles_and_link_lists_are_gone
    # Near-duplicate tiles removed from home (pages still exist elsewhere).
    %w[
      /treningi-aikido-gdynia.html
      /aikido-dla-doroslych-gdynia.html
    ].each do |href|
      refute_includes quick_nav_block(pl_template), "href=\"#{href}\"",
        "PL quick-nav must not contain #{href}"
    end
    refute_includes pl_template, "Najważniejsze strony na start"
    refute_includes pl_template, "Dlaczego Aikido?"
    refute_includes pl_template, "Nasza droga"

    refute_includes en_template, "What is Aikido?</a>"
    refute_includes en_template, "Our Path"
    refute_includes en_template, "Why Aikido?"
  end

  def test_schedule_facts_present_in_first_viewport_section
    assert_includes pl_template, "20:00"
    assert_includes pl_template, "Grudzińskiego"
    assert_match(/bezpłatny|gratis/i, pl_template)
    assert_includes pl_template, "7 kyu", "grade facts must survive the shortening"
    assert_includes pl_template, "hakam", "hakama fact must survive the shortening"
    assert_includes pl_template, "12–13", "minimum age must survive the shortening"

    assert_includes en_template, "8:00"
    assert_includes en_template, "Grudzińskiego"
    assert_match(/first class (is )?free/i, en_template)
    assert_includes en_template, "7 kyu", "EN grade facts must match PL"
    assert_includes en_template, "12–13", "EN minimum age must match PL"
  end

  def test_built_home_schedule_before_blog_and_hreflang_intact
    Dir.mktmpdir("poa-home-first-training-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )
      assert status.success?, "expected build to pass:\n#{output}"

      pl = File.read(File.join(export_dir, "index.html"))
      en = File.read(File.join(export_dir, "en/index.html"))

      # Schedule strip renders before the blog block.
      assert_operator pl.index("20:00"), :<, pl.index("Najnowsze wpisy"), "PL schedule must precede blog"
      assert_operator en.index("8:00"), :<, en.index("Latest Posts"), "EN schedule must precede blog"

      # Primary CTA resolves to a rendered page.
      assert_includes pl, 'href="/pierwszy-trening-aikido-gdynia.html"'
      assert File.file?(File.join(export_dir, "pierwszy-trening-aikido-gdynia.html"))
      assert_includes en, 'href="/en/first-aikido-training-gdynia.html"'
      assert File.file?(File.join(export_dir, "en/first-aikido-training-gdynia.html"))

      # Language alternates survive the rewrite (PL home carries hreflang;
      # EN pages resolve via the nav language switcher — LANG_URL_MAP only
      # maps PL->EN, a pre-existing contract this card does not change).
      assert_includes pl, 'hreflang="en"'
      assert_match(/<link rel="canonical"[^>]*>/, pl, "PL home must keep canonical")
      assert_match(/<link rel="canonical"[^>]*>/, en, "EN home must keep canonical")
      assert_includes en, 'class="nav-link lang-switcher" href="/"',
        "EN home must keep a working switcher back to PL home"
    end
  end
end

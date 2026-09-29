require_relative "test_helper"

# UIUX-17: guard the two architectural causes. Browser checks additionally
# exercise the real cascade and dropdown hit-testing (see delivery evidence).
class UiuxControlsTest < Minitest::Test
  def css
    File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
  end

  def test_header_treatment_is_not_applied_to_every_navigation_landmark
    refute_match(/^nav\s*\{/, css, "content indices must not become sticky headers")
    header = css[/body > nav \{([^}]+)\}/m, 1]
    refute_nil header
    assert_includes header, "position: sticky"
    assert_includes header, "z-index: 100"
  end

  def test_article_component_exclusions_do_not_accumulate_specificity
    refute_match(/\.article a:not\([^)]*\):not\(/, css)
    assert_includes css, ".article a:not(:where(.btn, .cta-button, .hero-btn"
  end

  def test_pills_have_visible_boundaries_and_keyboard_state
    base = css[/ul\.inline li a \{([^}]+)\}/m, 1]
    assert_includes base, "border: 1px solid #b52828"
    interactive = css[/ul\.inline li a:hover,\s*ul\.inline li a:focus-visible \{([^}]+)\}/m, 1]
    refute_nil interactive
    assert_includes interactive, "color: white"
    assert_includes interactive, "background: #cd3333"
  end
end

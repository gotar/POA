require_relative "test_helper"

# UIUX-04: in-flow links must be recognizable without hover and never by
# color alone; content lists must keep native markers; the suspended-training
# notice must meet 4.5:1; standalone read-more links must be touch-sized.
class ContentLinksListsAccessibilityTest < Minitest::Test
  LINK_CONTEXTS = %w[p li dd td blockquote].freeze
  MIN_CONTRAST = 4.5
  MIN_TOUCH_PX = 44
  BASE_FONT_PX = 16
  BASE_LINE_HEIGHT = 1.5

  def stripped_css
    File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
  end

  def declarations_for(selector)
    stripped_css.scan(/#{Regexp.escape(selector)} \{(.*?)\}/m).flatten
  end

  def test_no_global_list_reset_component_resets_only
    css = stripped_css

    refute_match(/^[ \t]*li[ \t]*\{[^}]*list-style:\s*none/m, css,
      "a bare li reset kills markers in kyu requirements and first-training lists")

    %w[ul.inline ul.error-page-links ul.yudansha-list].each do |selector|
      assert_match(/#{Regexp.escape(selector)}[^{]*\{[^}]*list-style:\s*none/m, css,
        "#{selector} must keep its own reset now the global one is gone")
    end
  end

  def test_content_lists_keep_native_markers
    css = stripped_css

    ul_rules = css[/\.content ul \{(?<rules>[^}]*)\}/m, :rules]
    refute_nil ul_rules, "expected a .content ul rule"
    assert_includes ul_rules, "list-style: disc",
      "content ul (kyu notes, first-training checklists) must show bullets"

    ol_rules = css[/\.content ol \{(?<rules>[^}]*)\}/m, :rules]
    refute_nil ol_rules, "expected a .content ol rule"
    assert_includes ol_rules, "list-style: decimal",
      "content ol (reishiki steps, guides) must show numbers"

    component_rules = css[/\.content ul\.inline,\s*\.content ul\.error-page-links,\s*\.content ul\.yudansha-list \{(?<rules>[^}]*)\}/m, :rules]
    refute_nil component_rules, "expected a component list opt-out rule"
    assert_includes component_rules, "list-style: none",
      "component pill/link/name lists inside .content must stay marker-free"
  end

  def test_content_links_underlined_and_meet_contrast
    selector = ".content :where(#{LINK_CONTEXTS.join(", ")}) a"
    blocks = declarations_for(selector)
    refute_empty blocks, "expected an in-flow content link rule for #{LINK_CONTEXTS.join("/")}"

    rules = blocks.first
    assert_includes rules, "text-decoration: underline",
      "content links (kontakt lead included) must not rely on hover or color alone"

    color = rules[/(?<![0-9a-f])#(?<hex>[0-9a-f]{6})/i, :hex]
    refute_nil color, "content link rule must set an explicit text color"
    assert_operator contrast_ratio(color, "ffffff"), :>=, MIN_CONTRAST,
      "##{color} on white must reach #{MIN_CONTRAST}:1, got #{contrast_ratio(color, "ffffff").round(2)}:1"

    focus = declarations_for("#{selector}:focus-visible")
    refute_empty focus, "content links need a visible keyboard focus style"
    assert_includes focus.first, "outline:",
      "focus must be an outline, not just a color shift"
  end

  def test_suspended_training_notice_meets_contrast_in_both_languages
    {
      "templates/kontakt.html.erb" => "Zajęcia zawieszone",
      "templates/contact_en.html.erb" => "Classes suspended"
    }.each do |template, text|
      html = File.read(site_root.join(template))
      assert_includes html, 'class="status-suspended"',
        "#{template} must use the shared notice class"
      assert_includes html, text, "#{template} must keep its localized notice text"
      refute_includes html, "#999",
        "#{template} must not keep the 2.84:1 inline #999"
    end

    blocks = declarations_for(".status-suspended")
    refute_empty blocks, "expected a .status-suspended rule"
    color = blocks.first[/(?<![0-9a-f])#(?<hex>[0-9a-f]{6})/i, :hex]
    refute_nil color, ".status-suspended must set an explicit text color"
    assert_operator contrast_ratio(color, "ffffff"), :>=, MIN_CONTRAST,
      "notice ##{color} on white must reach #{MIN_CONTRAST}:1, got #{contrast_ratio(color, "ffffff").round(2)}:1"
  end

  def test_read_more_links_meet_touch_target_size
    blocks = declarations_for(".news-read-more")
    refute_empty blocks, "expected a .news-read-more rule"
    rules = blocks.first

    vertical = rules.scan(/padding-(?:top|bottom):\s*(?<v>[0-9.]+)rem/).flatten.map(&:to_f).sum
    min_height = rules[/min-height:\s*(?<h>[0-9.]+)px/, :h].to_f
    line_box = BASE_FONT_PX * BASE_LINE_HEIGHT

    total = min_height.positive? ? min_height : line_box + vertical * BASE_FONT_PX
    assert_operator total, :>=, MIN_TOUCH_PX,
      ".news-read-more must reach a #{MIN_TOUCH_PX}px target (line box #{line_box}px + padding), got #{total.round(1)}px"
  end

  private

  # WCAG 2.x relative luminance + contrast ratio, computed from the actual
  # stylesheet values so the test fails if anyone darkens/lightens past 4.5:1.
  def relative_luminance(hex)
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) / 255.0 }.map do |v|
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast_ratio(foreground_hex, background_hex)
    l1 = relative_luminance(foreground_hex)
    l2 = relative_luminance(background_hex)
    lighter, darker = [l1, l2].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end
end

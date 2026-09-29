require_relative "test_helper"
require "open3"

# Shared layouts appear on every page. Keep the keyboard route around their
# repeated navigation explicit, localized, and protected from accidental removal.
class SharedLayoutAccessibilityTest < Minitest::Test
  LAYOUTS = {
    "templates/layouts/site.html.erb" => {
      skip_text: "Przejdź do treści",
      nav_label: "Główna nawigacja"
    },
    "templates/layouts/site_en.html.erb" => {
      skip_text: "Skip to content",
      nav_label: "Primary navigation"
    }
  }.freeze

  BACK_TO_TOP_BUTTONS = {
    "templates/layouts/site.html.erb" => {
      generated_path: "index.html",
      label: "Przewiń do góry"
    },
    "templates/layouts/site_en.html.erb" => {
      generated_path: "en/index.html",
      label: "Scroll to top"
    }
  }.freeze

  LANGUAGE_SWITCHERS = {
    "index.html" => {
      href: "/en/",
      title: "English",
      label: "Przełącz język na angielski",
      text: "EN"
    },
    "en/index.html" => {
      href: "/",
      title: "Polski",
      label: "Switch language to Polish",
      text: "PL"
    }
  }.freeze

  MOBILE_NAVIGATION_TOGGLES = {
    "index.html" => {
      menu_id: "primary-navigation",
      open_label: "Otwórz menu nawigacyjne",
      close_label: "Zamknij menu nawigacyjne"
    },
    "en/index.html" => {
      menu_id: "primary-navigation",
      open_label: "Open navigation menu",
      close_label: "Close navigation menu"
    }
  }.freeze

  DROPDOWN_CONTROLS = {
    "index.html" => [
      { label: "Dojo", menu_id: "dropdown-1-menu" },
      { label: "Blog", menu_id: "dropdown-2-menu" },
      { label: "Aikido", menu_id: "dropdown-3-menu" },
      { label: "Dla Trenujących", menu_id: "dropdown-4-menu" },
      { label: "Linia Przekazu", menu_id: "dropdown-5-menu" }
    ],
    "en/index.html" => [
      { label: "Dojo", menu_id: "dropdown-1-menu" },
      { label: "Blog", menu_id: "dropdown-2-menu" },
      { label: "Aikido", menu_id: "dropdown-3-menu" },
      { label: "For Practitioners", menu_id: "dropdown-4-menu" },
      { label: "Lineage", menu_id: "dropdown-5-menu" }
    ]
  }.freeze

  def test_shared_layouts_provide_localized_skip_link_and_landmarks
    LAYOUTS.each do |path, expectations|
      layout = File.read(site_root.join(path))
      skip_link = %(<a class="skip-link" href="#main-content">#{expectations[:skip_text]}</a>)

      assert_includes layout, skip_link, "#{path} must expose its localized skip link"
      assert_operator layout.index(skip_link), :<, layout.index("<nav"), "#{path} must place the skip link before repeated navigation"
      assert_includes layout, %(<nav aria-label="#{expectations[:nav_label]}">)
      assert_includes layout, '<main id="main-content" tabindex="-1">'
    end
  end

  def test_back_to_top_button_hides_decorative_icon_from_screen_readers
    back_to_top_svg = %(<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">)

    BACK_TO_TOP_BUTTONS.each do |path, expectations|
      layout = File.read(site_root.join(path))
      button = %(<button class="back-to-top" aria-label="#{expectations[:label]}">)

      assert_includes layout, button, "#{path} must expose a localized label on the back-to-top button"
      assert_includes layout, back_to_top_svg, "#{path} must hide the decorative back-to-top icon from screen readers"
      assert_operator layout.index(button), :<, layout.index(back_to_top_svg), "#{path} must keep the hidden icon inside the labeled button"
    end

    Dir.mktmpdir("poa-back-to-top-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )

      assert status.success?, "expected build to pass:\n#{output}"

      BACK_TO_TOP_BUTTONS.each do |path, expectations|
        html = File.read(File.join(export_dir, expectations[:generated_path]))
        label = expectations[:label]

        assert_includes html, %(<button class="back-to-top" aria-label="#{label}">), "#{expectations[:generated_path]} must render the localized back-to-top button"
        assert_includes html, back_to_top_svg, "#{expectations[:generated_path]} must render the decorative back-to-top icon hidden from screen readers"
      end
    end
  end

  def test_skip_link_is_hidden_offscreen_until_focus
    css = File.read(site_root.join("assets/style.css"))
    default_rule = css.match(/\.skip-link \{(?<rules>.*?)^\}/m)
    focus_rule = css.match(/\.skip-link:focus,\n\.skip-link:focus-visible \{(?<rules>.*?)^\}/m)

    assert default_rule, "expected a base .skip-link rule"
    assert_includes default_rule[:rules], "position: fixed;"
    assert_includes default_rule[:rules], "z-index: 10001;"
    assert_includes default_rule[:rules], "transform: translateY(-110%);"

    assert focus_rule, "expected a focus rule for .skip-link"
    assert_includes focus_rule[:rules], "outline: 3px solid #1f1f1f;"
    assert_includes focus_rule[:rules], "transform: translateY(0);"
  end

  def test_skip_link_moves_keyboard_focus_to_main_content_before_smooth_scrolling
    script = File.read(site_root.join("assets/app.js"))

    assert_match(
      /if \(targetId === '#main-content'\) \{\s+targetElement\.focus\(\{ preventScroll: true \}\);\s+\}\s+targetElement\.scrollIntoView\(\{\s+behavior: 'smooth'/m,
      script,
      "the intercepted skip link must move keyboard focus to main before scrolling"
    )
  end

  def test_generated_navigation_controls_have_localized_accessible_names
    Dir.mktmpdir("poa-navigation-controls-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )

      assert status.success?, "expected build to pass:\n#{output}"

      LANGUAGE_SWITCHERS.each do |path, expectations|
        html = File.read(File.join(export_dir, path))
        expected_link = %(<a class="nav-link lang-switcher" href="#{expectations[:href]}" title="#{expectations[:title]}" aria-label="#{expectations[:label]}">#{expectations[:text]}</a>)

        assert_includes html, expected_link, "#{path} must expose a localized language-switcher name"
      end

      MOBILE_NAVIGATION_TOGGLES.each do |path, expectations|
        html = File.read(File.join(export_dir, path))
        expected_button = <<~HTML.strip
          <button
              class="nav-toggle"
              type="button"
              hidden
              aria-expanded="false"
              aria-controls="#{expectations[:menu_id]}"
              aria-label="#{expectations[:open_label]}"
              data-open-label="#{expectations[:open_label]}"
              data-close-label="#{expectations[:close_label]}"
            >
              <span aria-hidden="true"></span>
            </button>
        HTML

        assert_includes html, expected_button, "#{path} must expose a semantic, localized mobile-menu control"
        assert_includes html, %(<div class="nav-menu" id="#{expectations[:menu_id]}">), "#{path} must expose the menu controlled by its mobile-menu button"
      end

      DROPDOWN_CONTROLS.each do |path, controls|
        html = File.read(File.join(export_dir, path))

        controls.each do |control|
          expected_button = /<button\s+class="dropdown-label"\s+type="button"\s+aria-expanded="false"\s+aria-controls="#{Regexp.escape(control[:menu_id])}"\s*>\s*#{Regexp.escape(control[:label])}\s*<\/button>/m

          assert_match expected_button, html, "#{path} must expose #{control[:label].inspect} as a keyboard-operable dropdown control"
          assert_includes html, %(<div class="dropdown-content" id="#{control[:menu_id]}">), "#{path} must expose the submenu controlled by #{control[:label].inspect}"
        end
      end
    end
  end

  def test_mobile_navigation_script_updates_semantic_state_and_handles_escape
    script = File.read(site_root.join("assets/app.js"))

    assert_includes script, "function initMobileNavigation()"
    assert_includes script, "menu.dataset.mobileMenuReady = 'true';"
    assert_includes script, "toggle.hidden = false;"
    assert_includes script, "toggle.addEventListener('click'"
    assert_includes script, "toggle.setAttribute('aria-expanded', String(expanded));"
    assert_includes script, "toggle.setAttribute('aria-label', expanded ? closeLabel : openLabel);"
    assert_includes script, "event.key === 'Escape'"
    assert_includes script, "setExpanded(false, true);"
  end

  def test_mobile_navigation_remains_available_without_javascript
    css = File.read(site_root.join("assets/style.css"))

    assert_includes css, ".nav-toggle[hidden] {"
    assert_includes css, ".nav-menu[data-mobile-menu-ready] {"
    assert_includes css, ".nav-toggle[aria-expanded=\"true\"]~.nav-menu[data-mobile-menu-ready] {"
    assert_includes css, ".dropdown:not([data-dropdown-ready]) .dropdown-content {"
  end

  def test_dropdown_navigation_supports_keyboard_disclosure
    css = File.read(site_root.join("assets/style.css"))
    script = File.read(site_root.join("assets/app.js"))

    assert_includes css, ".dropdown:not([data-dropdown-ready]):focus-within .dropdown-content,"
    assert_includes css, ".dropdown[data-dropdown-ready] .dropdown-label[aria-expanded=\"true\"] + .dropdown-content"
    assert_includes css, ".dropdown-label:focus-visible {"

    assert_includes script, "function initDropdownNavigation()"
    assert_includes script, "dropdown.dataset.dropdownReady = 'true';"
    assert_includes script, "toggle.addEventListener('click'"
    assert_includes script, "dropdown.addEventListener('focusout'"
    assert_includes script, "event.key !== 'Escape'"
    assert_includes script, "setExpanded(activeDropdown.toggle, false);"
  end

  def test_dropdown_visibility_has_single_source_of_truth
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    reveal_parts = []
    css.scan(/([^{}]+)\{([^{}]*)\}/m) do |selector, declarations|
      selector = selector.gsub(/\s+/, " ").strip
      next unless declarations.match?(/display:\s*(block|flex|list-item|table|grid|inline\S*)/)

      selector.split(",").each do |part|
        part = part.strip
        reveal_parts << part if part.end_with?(".dropdown-content")
      end
    end

    refute_empty reveal_parts, "expected at least one rule that reveals .dropdown-content"

    js_gated = reveal_parts.select do |part|
      part.include?("[data-dropdown-ready]") && !part.include?(":not([data-dropdown-ready])")
    end
    refute_empty js_gated, "expected a JS-gated reveal rule for .dropdown-content"
    js_gated.each do |part|
      assert_includes part, 'aria-expanded="true"',
        "#{part} is JS-gated and must require aria-expanded=true"
    end

    bare_overrides = reveal_parts.reject do |part|
      part.include?("aria-expanded") || part.include?(":not([data-dropdown-ready])")
    end
    assert_empty bare_overrides,
      ":hover/:focus-within must never override a closed JS toggle state: #{bare_overrides.join("; ")}"
  end

  def test_hamburger_meets_minimum_target_size
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    toggle_blocks = css.scan(/^\.nav-toggle \{([^{}]*)\}/m).flatten
    refute_empty toggle_blocks, "expected a base .nav-toggle rule"

    sizes = toggle_blocks.map do |rules|
      [rules[/min-width:\s*(?<px>\d+)px/, :px]&.to_i, rules[/min-height:\s*(?<px>\d+)px/, :px]&.to_i]
    end

    assert sizes.any? { |(width, height)| !width.nil? && !height.nil? && width >= 44 && height >= 44 },
      "expected .nav-toggle to guarantee a >=44x44 target, got #{sizes.inspect}"
  end

  def test_open_mobile_menu_scrolls_within_viewport
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    match = css.match(/\.nav-toggle\[aria-expanded="true"\]~\.nav-menu\[data-mobile-menu-ready\] \{(?<rules>[^{}]*)\}/m)
    assert match, "expected an explicit show-rule for the open mobile menu"

    assert_includes match[:rules], "overflow-y: auto;"
    assert_match(/max-height:\s*calc\(100(d)?vh/, match[:rules])
  end

  def test_dropdown_state_resets_on_breakpoint_change
    script = File.read(site_root.join("assets/app.js"))

    assert_includes script, "window.matchMedia('(min-width: 769px)')"
    assert_includes script, "resetDropdownsOnBreakpointChange"
    assert_includes script, "addEventListener('change', resetDropdownsOnBreakpointChange)"
  end

  def test_escape_closes_one_layer_at_a_time
    script = File.read(site_root.join("assets/app.js"))

    assert_includes script, "const openDropdowns = dropdowns.filter"
    assert_includes script, "setExpanded(activeDropdown.toggle, false);"
    assert_includes script, "event.stopImmediatePropagation();"
  end

  def test_desktop_dropdown_menu_scrolls_within_viewport
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    menu_blocks = css.scan(/^\.dropdown-content \{([^{}]*)\}/m).flatten
    refute_empty menu_blocks, "expected a base .dropdown-content rule"

    assert menu_blocks.any? { |rules| rules.include?("max-height:") && rules.include?("overflow-y: auto;") },
      "expected .dropdown-content to scroll a long submenu within the viewport"
  end

  def test_header_auto_hide_respects_reduced_motion
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    reduced_motion = css[/@media \(prefers-reduced-motion: reduce\) \{(?<block>.*)\}\s*\.svg-decor/m, :block]
    assert reduced_motion, "expected a prefers-reduced-motion block"
    assert_includes reduced_motion, "nav {"
    assert_includes reduced_motion, "transition: none;"
  end

  def test_mobile_menu_closes_on_outside_tap_and_link_activation
    script = File.read(site_root.join("assets/app.js"))

    assert_includes script, "if (!event.target.closest('nav')) setExpanded(false);"
    assert_includes script, "menu.addEventListener('click'"
    assert_includes script, "if (event.target.closest('a')) setExpanded(false);"
  end

  def test_header_auto_hide_keeps_open_menu_and_focus_visible
    script = File.read(site_root.join("assets/app.js"))

    assert_includes script, "function menuOrFocusActive()"
    assert_includes script, "nav.querySelector('.nav-toggle[aria-expanded=\"true\"]')"
    assert_includes script, "nav.querySelector('.dropdown-label[aria-expanded=\"true\"]')"
    assert_includes script, "nav.contains(document.activeElement)"
  end

  def test_mobile_menu_dismisses_on_outside_tap_and_link_activation
    script = File.read(site_root.join("assets/app.js"))

    assert_includes script, "menu.addEventListener('click'"
    assert_includes script, "if (event.target.closest('a')) setExpanded(false);"
    assert_includes script, "if (!event.target.closest('nav')) setExpanded(false);"
  end

  def test_header_hide_transition_lives_in_css_and_respects_reduced_motion
    css = File.read(site_root.join("assets/style.css"))
    script = File.read(site_root.join("assets/app.js"))

    assert_includes css, "transition: transform 0.3s ease;"
    refute_includes script, "nav.style.transition",
      "the hide transition must be CSS-controlled so reduced-motion can override it"
    assert_match(/@media \(prefers-reduced-motion: reduce\)[\s\S]*?nav \{\s*transition: none;\s*\}/m, css)
  end

  def test_every_english_view_uses_the_english_layout
    views = Dir[site_root.join("lib/site/views/en/**/*.rb").to_s]
    missing_layout = views.reject { |path| File.read(path).include?('config.layout = "site_en"') }

    assert_empty missing_layout, "English views must use site_en: #{missing_layout.join(", ")}"
  end
end

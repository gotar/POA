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
  end

  def test_every_english_view_uses_the_english_layout
    views = Dir[site_root.join("lib/site/views/en/**/*.rb").to_s]
    missing_layout = views.reject { |path| File.read(path).include?('config.layout = "site_en"') }

    assert_empty missing_layout, "English views must use site_en: #{missing_layout.join(", ")}"
  end
end

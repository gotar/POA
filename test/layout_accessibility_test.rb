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

  def test_generated_language_switchers_have_localized_accessible_names
    Dir.mktmpdir("poa-language-switcher-") do |export_dir|
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
    end
  end

  def test_every_english_view_uses_the_english_layout
    views = Dir[site_root.join("lib/site/views/en/**/*.rb").to_s]
    missing_layout = views.reject { |path| File.read(path).include?('config.layout = "site_en"') }

    assert_empty missing_layout, "English views must use site_en: #{missing_layout.join(", ")}"
  end
end

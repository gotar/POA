require_relative "test_helper"
require "open3"

# UIUX-16 (t_d60a50c5): tablet regression — viewports 769..1024px (m.in. 820,
# iPad Air) showed a horizontal overflow: documentElement.scrollWidth 863px
# at 820px, offender A.nav-link.lang-switcher spilling past the viewport.
# Bisected against the UIUX-11 merge (f3347a71, sw 810 at 820px): UIUX-15
# added <span class="logo-short">POA</span> to the header, and together with
# the poa.svg calligraphy (~205px at 28px height) the desktop nav row no
# longer fits 769..862px viewports.
#
# The fix keeps the owner-approved branding intact: on desktop (>1024px) the
# full name + calligraphy stay; on mobile (<=768px) logo-short already
# carries the brand. In the 769..1024 band the calligraphy block
# (nav .logo .logo-text) is now hidden and logo-short stays visible —
# exactly the mobile pattern, no new breakpoint, no menu behavior change.
#
# A headless-browser probe (agent-browser, Chromium) is the primary evidence
# (matrix.jsonl in the card artifacts). This test guards the stylesheet
# contract statically: the hiding rule must live INSIDE the 769..1024 media
# block (not anywhere else), and the logo-short visible rule must be kept,
# so neither half of the contract can silently disappear.
class HeaderTabletOverflowTest < Minitest::Test
  MEDIA_769_1024 = "@media only screen and (min-width: 769px) and (max-width: 1024px)".freeze

  def stylesheet
    @stylesheet ||= File.read(File.join(site_root, "assets/style.css"))
  end

  def media_769_1024_block
    start_at = stylesheet.index(MEDIA_769_1024)
    assert start_at, "expected the 769..1024 tablet media block in assets/style.css"
    brace_at = stylesheet.index("{", start_at)
    depth = 0
    pos = brace_at
    while pos < stylesheet.length
      depth += 1 if stylesheet[pos] == "{"
      depth -= 1 if stylesheet[pos] == "}"
      return stylesheet[brace_at..pos] if depth.zero?
      pos += 1
    end
    flunk "unbalanced braces in the 769..1024 media block"
  end

  def test_tablet_band_hides_calligraphy_block
    block = media_769_1024_block
    assert_match(/nav\s+\.logo\s+\.logo-text\s*\{\s*display:\s*none\s*;?\s*\}/, block,
      "769..1024 band must hide nav .logo .logo-text (poa.svg calligraphy) — the 820px overflow guard")
  end

  def test_tablet_band_keeps_full_name_hidden
    block = media_769_1024_block
    assert_match(/nav\s+\.logo\s+span\s*\{\s*display:\s*none\s*;?\s*\}/, block,
      "769..1024 band must keep the full-name span hidden")
  end

  def test_logo_short_stays_visible_up_to_1024
    assert_match(/nav\s+\.logo\s+\.logo-short\s*\{\s*display:\s*inline/, stylesheet,
      "logo-short must stay the visible brand carrier up to 1024px")
  end

  def build_once
    @build_once ||= begin
      dir = Dir.mktmpdir("poa-header-tablet-")
      at_exit { FileUtils.remove_entry(dir) }
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )
      assert status.success?, "expected build to pass:\n#{output}"
      dir
    end
  end

  def test_built_header_carries_all_three_brand_elements
    %w[index.html en/index.html kontakt.html].each do |path|
      html = File.read(File.join(build_once, path))
      assert_includes html, 'class="logo-text"', "#{path}: header must keep the calligraphy block for desktop"
      assert_includes html, 'class="logo-short"', "#{path}: header must keep the short POA signature"
      assert_includes html, "toyoda.svg", "#{path}: header must keep the mark"
    end
  end
end

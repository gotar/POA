require_relative "test_helper"
require "open3"
require "tmpdir"

# UIUX-03 (t_efffab57): wide tables (Mui, events 2026) pushed
# documentElement.scrollWidth past innerWidth on 320/390px phones, and
# contact cards overflowed at 320px. The fix wraps wide tables in a
# keyboard-accessible inner scroller instead of masking the page.
#
# This test asserts behavior on built HTML, not mere selector presence:
# the wrapper must actually enclose the table, carry keyboard access,
# keep every column, and the stylesheet must not hide page-level overflow.
class TableOverflowTest < Minitest::Test
  WIDE_TABLES = {
    "blog/mui-dzialanie-bez-wymuszania.html" => {
      template: "templates/blog/mui.html.erb",
      label: "Przewijana tabela: mushin, mui i kuzushi — porównanie",
      hint: "Przesuń tabelę w bok, aby zobaczyć wszystkie kolumny.",
      probe: "無為 Mui (wu-wei)"
    },
    "en/blog/mui-acting-without-forcing.html" => {
      template: "templates/blog/mui_en.html.erb",
      label: "Scrollable table: mushin, mui and kuzushi — comparison",
      hint: "Scroll the table sideways to see all columns.",
      probe: "Mui (wu-wei)"
    },
    "wydarzenia/2026.html" => {
      template: "templates/wydarzenia/2026.html.erb",
      label: "Przewijana tabela: program seminariów BAA 2026",
      hint: "Przesuń tabelę w bok, aby zobaczyć wszystkie kolumny.",
      probe: "Germanov Shihan"
    },
    "en/events/2026.html" => {
      template: "templates/wydarzenia_en.html.erb",
      label: "Scrollable table: BAA 2026 seminar program",
      hint: "Scroll the table sideways to see all columns.",
      probe: "Germanov Shihan"
    }
  }.freeze

  def built_pages
    @built_pages ||= begin
      dir = Dir.mktmpdir("poa-table-overflow-")
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )
      assert status.success?, "expected build to pass:\n#{output}"
      dir
    end
  end

  def test_wide_tables_render_inside_keyboard_accessible_scroll_region
    WIDE_TABLES.each do |path, expectations|
      html = File.read(File.join(built_pages, path))

      wrapper = %(<div class="table-scroll" tabindex="0" role="region" aria-label="#{expectations[:label]}">)
      assert_includes html, wrapper, "#{path} must expose its wide table as a labeled scroll region"

      hint = %(<p class="table-scroll-hint">#{expectations[:hint]}</p>)
      assert_includes html, hint, "#{path} must carry a localized scroll hint"
      assert_operator html.index(hint), :<, html.index(wrapper),
        "#{path}: the scroll hint must precede the scroll region"

      region = html[html.index(wrapper)..]
      table_at = region.index("<table")
      close_at = region.index("</div>")
      refute_nil table_at, "#{path}: scroll region must contain a table"
      refute_nil close_at, "#{path}: scroll region must be closed"
      assert_operator table_at, :<, close_at, "#{path}: the table must sit inside the scroll region, not beside it"

      assert_includes region, expectations[:probe], "#{path} must keep its table content (no dropped columns)"
    end
  end

  def test_wide_tables_keep_all_columns
    html = File.read(File.join(built_pages, "wydarzenia/2026.html"))
    %w[Data Wydarzenie Lokalizacja Instruktor].each do |header|
      assert_includes html, "<th>#{header}</th>", "events table must keep its #{header} column"
    end

    mui = File.read(File.join(built_pages, "blog/mui-dzialanie-bez-wymuszania.html"))
    assert_includes mui, "<th>Wymiar</th>"
    assert_includes mui, "kuzushi"
  end

  def test_stylesheet_never_masks_page_level_overflow
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    css.scan(/([^{}]+)\{([^{}]*)\}/m) do |selector, declarations|
      selectors = selector.split(",").map { |part| part.gsub(/\s+/, " ").strip }
      next unless selectors.any? { |part| part == "html" || part == "body" }

      refute_match(/overflow(-x)?:\s*hidden/, declarations,
        "#{selectors.join(", ")} must not mask page overflow with clipping")
    end
  end

  def test_table_scroller_keeps_columns_and_confines_scroll
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    scroller = css.match(/\.table-scroll \{(?<rules>[^{}]*)\}/m)
    assert scroller, "expected a base .table-scroll rule"
    assert_includes scroller[:rules], "overflow-x: auto;"
    assert_includes scroller[:rules], "max-width: 100%;"

    inner = css.match(/\.table-scroll > table \{(?<rules>[^{}]*)\}/m)
    assert inner, "expected a .table-scroll > table rule"
    assert_includes inner[:rules], "width: 100%;"

    assert_includes css, ".table-scroll:focus-visible {",
      "the scroll region must show a visible focus indicator for keyboard users"
  end

  def test_contact_grid_fits_narrow_viewports_and_wraps_long_text
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    cards = css.match(/\.contact-cards \{(?<rules>[^{}]*)\}/m)
    assert cards, "expected a base .contact-cards rule"
    assert_includes cards[:rules], "minmax(min(280px, 100%), 1fr)",
      "contact grid must not enforce a fixed 280px minimum wider than the phone"

    card = css.match(/\.contact-card \{(?<rules>[^{}]*)\}/m)
    assert card, "expected a base .contact-card rule"
    assert_includes card[:rules], "min-width: 0;"

    link = css.match(/\.contact-info-item a \{(?<rules>[^{}]*)\}/m)
    assert link, "expected a .contact-info-item a rule"
    assert_includes link[:rules], "overflow-wrap: anywhere;",
      "long contact links must wrap instead of pushing the card wider"

    org = css.match(/\.organization-data dd \{(?<rules>[^{}]*)\}/m)
    assert org, "expected a .organization-data dd rule"
    assert_includes org[:rules], "overflow-wrap: anywhere;"

    mobile = css.match(/@media[^{]*max-width:\s*768px[^{]*\{(?<body>.*)\z/m)
    assert mobile, "expected the <=768px media block"
    assert_includes mobile[:body], ".contact-card {",
      "phones must get an explicit contact-card rule (reduced padding, min-width)"
  end
end

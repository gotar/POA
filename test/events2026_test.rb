require_relative "test_helper"

# UIUX-14: events 2026 — upcoming before the archive, readable on mobile.
#
# The program is explicit data (EVENTS_2026 in context.rb) with static
# past/nearest flags; the build never consults a clock, so ordering is
# fixed and deterministic. Templates render an Upcoming section first
# and an Archive second on the same URL. Section headings provide status;
# tables keep only four useful data columns, with neutral styling and
# mobile cards fed by td data-labels instead of a clipped wide table.
class Events2026Test < Minitest::Test
  PAGES = {
    ["views.event2026", "wydarzenia/2026.html", "pl"] => {
      upcoming_id: "nadchodzace",
      archive_id: "archiwum",
      headers: %w[Data Wydarzenie Lokalizacja Instruktor],
      labels: %w[Data Wydarzenie Lokalizacja Instruktor],
      empty_probe: "Aktualnie nie ma ogłoszonych nadchodzących wydarzeń."
    },
    ["views.en.event2026", "en/events/2026.html", "en"] => {
      upcoming_id: "upcoming",
      archive_id: "archive",
      headers: %w[Date Event Location Instructor],
      labels: %w[Date Event Location Instructor],
      empty_probe: "There are currently no announced upcoming events."
    }
  }.freeze

  def render_view(key, path)
    Site::Container[key].(context: make_context(current_path: path, root: site_root)).to_s
  end

  def test_upcoming_section_renders_before_archive_with_resolving_index
    PAGES.each do |(key, path, _lang), exp|
      html = render_view(key, path)

      upcoming_at = html.index(%(id="#{exp[:upcoming_id]}"))
      archive_at = html.index(%(id="#{exp[:archive_id]}"))
      refute_nil upcoming_at, "#{path}: upcoming section must render"
      refute_nil archive_at, "#{path}: archive section must render"
      assert_operator upcoming_at, :<, archive_at,
        "#{path}: upcoming must come before the archive"

      nav = html[%r{<nav class="events-index".*?</nav>}m]
      refute_nil nav, "#{path}: section index nav must render"
      %W[#{"##{exp[:upcoming_id]}"} #{"##{exp[:archive_id]}"}].each do |href|
        assert_includes nav, %(href="#{href}"),
          "#{path}: index must link #{href}"
        assert_includes html, %(id="#{href[1..]}"),
          "#{path}: index link #{href} must resolve to an id"
      end
    end
  end

  def test_all_events_dates_and_instructors_preserved_in_data_order
    data = Site::View::Context::EVENTS_2026
    assert_equal 12, data.size, "program must keep all 12 events"

    PAGES.each do |(key, path, _lang), exp|
      html = render_view(key, path)

      data.each do |entry|
        %i[date event location instructor].each do |field|
          assert_includes html, entry[field].to_s,
            "#{path}: #{field} #{entry[field].inspect} must be preserved"
        end
      end

      upcoming_html = html[html.index(%(id="#{exp[:upcoming_id]}"))...html.index(%(id="#{exp[:archive_id]}"))]
      archive_html = html[html.index(%(id="#{exp[:archive_id]}"))..]

      expected_upcoming = data.reject { |e| e[:past] }.map { |e| e[:event] }
      expected_archive = data.select { |e| e[:past] }.map { |e| e[:event] }
      assert_equal ["BAA and Aikikai Aikido Academy Seminar",
                    "BAA / Tendokan International Seminar",
                    "BAA / Tendokan International Seminar",
                    "BAA Seminar in Elin Pelin"], expected_upcoming
      assert_equal 8, expected_archive.size

      positions = expected_upcoming.map { |name| upcoming_html.index(name) }
      assert positions.all?, "#{path}: every upcoming event must sit in the upcoming section"
      assert_equal positions.sort, positions, "#{path}: upcoming keeps chronological data order"
      expected_archive.each do |name|
        assert_includes archive_html, name, "#{path}: #{name} must sit in the archive"
        refute_includes upcoming_html, name, "#{path}: past #{name} must not leak into upcoming"
      end
    end
  end

  def test_section_headings_replace_redundant_status_badges
    PAGES.each do |(key, path, _lang), exp|
      html = render_view(key, path)
      refute_includes html, '<th scope="col">Status</th>'
      refute_includes html, 'data-label="Status"'
      refute_includes html, 'status-badge'
      refute_includes html, 'special event-next'
      refute_match(/<p>[^<]*(?:etykiet|label)[^<]*<\/p>/, html,
        "#{path}: remove explanations of labels that no longer exist")
      assert_includes html, %(aria-labelledby="#{exp[:upcoming_id]}")
      assert_includes html, %(aria-labelledby="#{exp[:archive_id]}")
    end
  end

  def test_tables_keep_labeled_columns_and_data_labels_for_cards
    PAGES.each do |(key, path, _lang), exp|
      html = render_view(key, path)

      assert_equal 2, html.scan(/<table class="events-table">/).size,
        "#{path}: upcoming and archive each render a full table"
      exp[:headers].each do |header|
        assert_equal 2, html.scan(%(<th scope="col">#{header}</th>)).size,
          "#{path}: both tables keep the labeled #{header} column"
      end

      cells = html.scan(%r{<td data-label="([^"]+)">}).flatten
      assert_equal 12 * 4, cells.size, "#{path}: all 48 cells carry a data-label for card mode"
      assert_equal exp[:labels].sort, cells.uniq.sort,
        "#{path}: data-labels must match the visible column headers, no guessing"

      refute_includes html, "table-scroll",
        "#{path}: card tables replace the horizontal scroll wrapper, nothing clips at 320px"
    end
  end

  def test_pl_en_parity_same_program_both_languages
    pl = render_view("views.event2026", "wydarzenia/2026.html")
    en = render_view("views.en.event2026", "en/events/2026.html")

    Site::View::Context::EVENTS_2026.each do |entry|
      %i[date event location instructor].each do |field|
        assert_includes pl, entry[field].to_s, "PL must carry #{entry[field].inspect}"
        assert_includes en, entry[field].to_s, "EN must carry the same #{entry[field].inspect}"
      end
    end

    assert_equal pl.scan(/<tr/).size, en.scan(/<tr/).size,
      "both languages render the same row count"
  end

  def test_partition_helpers_boundary_shapes_without_a_clock
    ctx = make_context(current_path: "wydarzenia/2026.html", root: site_root)

    data = Site::View::Context::EVENTS_2026
    assert_equal 4, ctx.events_2026_upcoming(data).size
    assert_equal 8, ctx.events_2026_archive(data).size
    assert_equal data.first(8).map { |e| e[:event] },
                 ctx.events_2026_archive(data).map { |e| e[:event] }

    # Seam: a non-past nearest entry stays first in upcoming even when it
    # directly follows the past block.
    upcoming = ctx.events_2026_upcoming(data)
    assert upcoming.first[:nearest], "the seam row leads the upcoming section"
    assert_equal "BAA and Aikikai Aikido Academy Seminar", upcoming.first[:event]

    # End of season: everything past means an empty upcoming list, which is
    # what drives the honest empty-state branch in the templates.
    all_past = data.map { |e| e.merge(past: true, nearest: false) }
    assert_empty ctx.events_2026_upcoming(all_past)
    assert_equal 12, ctx.events_2026_archive(all_past).size

    assert_empty ctx.events_2026_upcoming([]), "empty program has no upcoming"
    assert_empty ctx.events_2026_archive([]), "empty program has no archive"
  end

  def test_status_labels_and_classes_cover_all_states_both_languages
    ctx = make_context(current_path: "wydarzenia/2026.html", root: site_root)
    past = { past: true, nearest: false }
    near = { past: false, nearest: true }
    soon = { past: false, nearest: false }

    assert_equal "Minione", ctx.event_status_label(past, "pl")
    assert_equal "Najbliższe", ctx.event_status_label(near, "pl")
    assert_equal "Nadchodzące", ctx.event_status_label(soon, "pl")
    assert_equal "Past", ctx.event_status_label(past, "en")
    assert_equal "Next", ctx.event_status_label(near, "en")
    assert_equal "Upcoming", ctx.event_status_label(soon, "en")

    assert_equal "status-past", ctx.event_status_class(past)
    assert_equal "status-next", ctx.event_status_class(near)
    assert_equal "status-upcoming", ctx.event_status_class(soon)
  end

  def test_empty_state_branch_is_server_rendered_in_both_templates
    {
      "templates/wydarzenia/2026.html.erb" =>
        "Aktualnie nie ma ogłoszonych nadchodzących wydarzeń.",
      "templates/wydarzenia_en.html.erb" =>
        "There are currently no announced upcoming events."
    }.each do |template, probe|
      raw = File.read(site_root.join(template))
      assert_includes raw, "if upcoming.empty?",
        "#{template}: the empty branch must be server-rendered, not JS-injected"
      assert_includes raw, probe,
        "#{template}: empty state is an honest no-dates message, never a fictional date"
    end
  end

  def test_no_clock_in_events_build_path
    sources = [
      File.read(site_root.join("templates/wydarzenia/2026.html.erb")),
      File.read(site_root.join("templates/wydarzenia_en.html.erb"))
    ]
    sources.each do |src|
      refute_match(/Time\.|Date\.|DateTime/, src, "events templates must not consult a clock")
    end

    context_src = File.read(site_root.join("lib/site/view/context.rb"))
    events_src = context_src[context_src.index("EVENTS_2026")...context_src.index("def canonical_url")]
    refute_match(/Time\.now|Date\.today|Time\.new|Date\.new/, events_src,
      "events data and helpers must be static for a deterministic build")
  end

  def test_css_neutral_tables_cards_and_empty_state
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    headers = css[/table\.events-table th \{([^}]+)\}/m, 1]
    refute_nil headers, "neutral header colors must be scoped to events only"
    assert_includes headers, "background-color: #f1f3f5"
    assert_includes headers, "color: #333"
    refute_includes css, "table.events-table tr.event-next td"

    assert_match(/\.events-empty \{(?<rules>[^{}]*)\}/m, css, "expected an .events-empty rule")

    mobile = css.match(/@media[^{]*max-width:\s*768px[^{]*\{(?<body>.*)\z/m)
    assert mobile, "expected the <=768px media block"
    body = mobile[:body]
    assert_includes body, ".events-table thead {",
      "card mode hides the header row accessibly (th stays for assistive tech)"
    assert_includes body, "content: attr(data-label);",
      "cards label every value with its column header"
    assert_includes body, "overflow-wrap: anywhere;",
      "long locations wrap instead of pushing the card past 320px"
    assert_includes body, "min-width: 0;",
      "cells must not enforce a minimum wider than the phone"
    refute_includes body, ".events-table tbody tr.special {",
      "cards must not reintroduce loud red nearest-event borders"
  end
end

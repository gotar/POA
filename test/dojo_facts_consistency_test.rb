require_relative "test_helper"
require "open3"

# Guards the facts that are intentionally repeated in several places (dojo
# pages, contact pages, first-training pages, global footer). Presence checks
# cannot detect drift: a page that says both "20:00–21:30" and a mistyped
# "20:00–22:30" still contains the expected string. These assertions therefore
# compare every occurrence of a dojo's schedule, venue street number and phone
# link in each page, so any contradicting variant fails.
class DojoFactsConsistencyTest < Minitest::Test
  GDYNIA_PAGES = %w[
    gdynia.html kontakt.html pierwszy-trening-aikido-gdynia.html
  ].freeze
  GDYNIA_EN_PAGES = %w[
    en/gdynia.html en/contact.html en/first-aikido-training-gdynia.html
  ].freeze
  RACIBORZ_PAGES = %w[
    raciborz.html kontakt.html pierwszy-trening-aikido-gdynia.html
  ].freeze
  RACIBORZ_EN_PAGES = %w[
    en/raciborz.html en/contact.html en/first-aikido-training-gdynia.html
  ].freeze
  KNOWN_PHONES = %w[48608019078 48724940651].freeze
  GDYNIA_PHONE = "48608019078"
  RACIBORZ_PHONE = "48724940651"
  # Start/end pairs are unique per dojo, so they identify a schedule without
  # depending on the surrounding presentation ("20:00 - 21:30" in a table,
  # "od 20:00 do 21:30" in prose, "8:00 PM–9:30 PM" in English).
  PL_RANGES = [%w[20:00 21:30], %w[17:30 19:30]].freeze
  EN_RANGES = [%w[8:00 9:30], %w[17:30 19:30]].freeze
  # Only the contact pages also list the organization office, which shares the
  # Racibórz street with the training venue.
  CONTACT_PAGES = %w[kontakt.html en/contact.html].freeze
  GDYNIA_DIRECTIONS = "54.5441767,18.5432137".freeze
  RACIBORZ_DIRECTIONS_FRAGMENT = "Szkolno-Przedszkolny".freeze
  GDYNIA_INSTRUCTOR = "Oskar Szrajer".freeze
  RACIBORZ_INSTRUCTOR = "Krzysztof Seget".freeze

  def setup
    @output = Dir.mktmpdir("poa-dojo-facts-")
    output, status = Open3.capture2e(
      { "EXPORT_DIR" => @output },
      File.join(site_root, "bin/build"),
      chdir: site_root.to_s
    )
    assert status.success?, "expected site build to pass:\n#{output}"
  end

  def teardown
    FileUtils.remove_entry(@output) if @output && Dir.exist?(@output)
  end

  def page(path)
    File.read(File.join(@output, path))
  end

  def normalize(text)
    text.downcase.gsub(/\s+/, "").tr("-", "–")
  end

  def footer_of(path)
    content = page(path)
    start = content.index('<footer class="site-footer">')
    refute_nil start, "#{path}: footer not rendered"
    content[start..]
  end

  # Every time range on the page must be one of the two canonical dojo
  # schedules, and the dojo's own schedule must be present.
  def assert_only_known_schedules(content, allowed, required, label)
    ranges = normalize(content)
             .scan(/(\d{1,2}:\d{2})(?:[ap]m)?(?:–|do|to)(\d{1,2}:\d{2})(?:[ap]m)?/)
             .uniq
    refute_empty ranges, "#{label}: no schedule range found"
    assert_empty ranges - allowed, "#{label}: unknown or drifted schedule range(s): #{(ranges - allowed).inspect}"
    assert_includes ranges, required, "#{label}: missing expected schedule #{required.join('–')}"
  end

  # Every mention of a street must use an allowed building number, and the
  # expected one must be present (the organization office shares the
  # Racibórz street with the training venue).
  def assert_street_numbers(content, street_pattern, allowed, required, label)
    numbers = content.scan(/#{street_pattern}[^\d]{0,4}(\d+)/i).flatten.uniq
    assert_includes numbers, required, "#{label}: missing expected street number #{required}"
    assert_empty numbers - allowed, "#{label}: unexpected street number(s): #{(numbers - allowed).inspect}"
  end

  def assert_only_known_phone_links(content, required, label)
    targets = content.scan(/tel:[^"'\s]+/).uniq
    refute_empty targets, "#{label}: no phone links found"
    malformed = targets.reject { |href| href.match?(/\Atel:\+\d{9,15}\z/) }
    assert_empty malformed, "#{label}: malformed telephone target(s): #{malformed.inspect}"
    digits = targets.map { |href| href.gsub(/\D/, "") }.uniq
    assert_empty digits - KNOWN_PHONES, "#{label}: unknown phone number: #{(digits - KNOWN_PHONES).inspect}"
    assert_includes digits, required, "#{label}: missing the dojo's own phone link"
  end

  # Every Google directions link must point at one of the two canonical
  # destinations, and the dojo's own destination must be present.
  def assert_directions(content, required, label)
    targets = content.scan(/maps\/dir\/\?[^"']*destination=([^"'&]+)/).flatten
                .map { |value| value.tr("+", " ").gsub("%2C", ",") }.uniq
    refute_empty targets, "#{label}: no directions link found"
    unknown = targets.reject { |value| canonical_destination?(value) }
    assert_empty unknown, "#{label}: unknown directions destination(s): #{unknown.inspect}"
    assert(targets.any? { |value| value.include?(required) }, "#{label}: missing directions for #{required}")
  end

  def canonical_destination?(value)
    value.include?(GDYNIA_DIRECTIONS) || value.include?(RACIBORZ_DIRECTIONS_FRAGMENT)
  end

  def assert_gdynia_facts(content, label, english: false)
    # English pages also carry the machine-readable 20:00-21:30 opening hours
    # in the LocalBusiness JSON-LD, so both representations are allowed.
    allowed = (PL_RANGES + EN_RANGES).uniq
    required = english ? %w[8:00 9:30] : %w[20:00 21:30]
    assert_only_known_schedules(content, allowed, required, label)
    assert_street_numbers(content, "Grudzińskiego", ["1"], "1", label)
    assert_only_known_phone_links(content, GDYNIA_PHONE, label)
    assert_directions(content, GDYNIA_DIRECTIONS, label)
    assert_includes content, "Sensei #{GDYNIA_INSTRUCTOR}", "#{label}: missing the Gdynia instructor"
  end

  def assert_raciborz_facts(content, label, english: false, contact_page: false)
    allowed = (PL_RANGES + EN_RANGES).uniq
    street_numbers = contact_page ? %w[48 50] : %w[48]
    assert_only_known_schedules(content, allowed, %w[17:30 19:30], label)
    assert_street_numbers(content, "Słowackiego", street_numbers, "48", label)
    assert_only_known_phone_links(content, RACIBORZ_PHONE, label)
    assert_directions(content, RACIBORZ_DIRECTIONS_FRAGMENT, label)
    assert_includes content, "Sensei #{RACIBORZ_INSTRUCTOR}", "#{label}: missing the Racibórz instructor"
  end

  def test_gdynia_facts_are_consistent_across_pages_and_footer
    GDYNIA_PAGES.each { |path| assert_gdynia_facts(page(path), path) }
    GDYNIA_EN_PAGES.each { |path| assert_gdynia_facts(page(path), path, english: true) }
    assert_gdynia_facts(footer_of("index.html"), "footer index.html")
    assert_gdynia_facts(footer_of("en/index.html"), "footer en/index.html", english: true)
  end

  def test_raciborz_facts_are_consistent_across_pages_and_footer
    RACIBORZ_PAGES.each { |path| assert_raciborz_facts(page(path), path, contact_page: CONTACT_PAGES.include?(path)) }
    RACIBORZ_EN_PAGES.each do |path|
      assert_raciborz_facts(page(path), path, english: true, contact_page: CONTACT_PAGES.include?(path))
    end
    assert_raciborz_facts(footer_of("index.html"), "footer index.html")
    assert_raciborz_facts(footer_of("en/index.html"), "footer en/index.html")
  end
end

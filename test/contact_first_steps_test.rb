require_relative "test_helper"

# UIUX-10 (t_e1d41657): contact starts with Gdynia + quick actions, and the
# Gdynia/training/first-class pages share one concise start card.
#
# Behavior (not selector presence): a visitor on a 390px screen gets the
# working facts first — full phone/mail/directions links, schedule, address,
# free first class — while the Raciborz headquarters data stays available
# below, explicitly labelled as the seat (not an active training hall).
class ContactFirstStepsTest < Minitest::Test
  CONTACT_PL = "templates/kontakt.html.erb".freeze
  CONTACT_EN = "templates/contact_en.html.erb".freeze

  START_PAGES = {
    "templates/gdynia.html.erb" => { contact: "/kontakt.html", schedule: "20:00" },
    "templates/treningi_aikido_gdynia.html.erb" => { contact: "/kontakt.html", schedule: "20:00" },
    "templates/pierwszy_trening_aikido_gdynia.html.erb" => { contact: "/kontakt.html", schedule: "20:00" },
    "templates/gdynia_en.html.erb" => { contact: "/en/contact.html", schedule: "8:00 PM" },
    "templates/aikido_training_gdynia_en.html.erb" => { contact: "/en/contact.html", schedule: "8:00 PM" },
    "templates/first_aikido_training_gdynia_en.html.erb" => { contact: "/en/contact.html", schedule: "8:00 PM" }
  }.freeze

  DIRECTIONS = "https://www.google.com/maps/dir/?api=1&destination=54.5441767,18.5432137".freeze

  def read(relative)
    File.read(site_root.join(relative).to_s)
  end

  def test_contact_gdynia_section_comes_before_organization_data
    pl = read(CONTACT_PL)
    assert_operator pl.index("Sesshinkan Dojo Gdynia"), :<, pl.index("Polska Organizacja Aikido"),
                    "PL contact must lead with the Gdynia dojo, not the organization data"

    en = read(CONTACT_EN)
    assert_operator en.index("Sesshinkan Dojo Gdynia"), :<, en.index("Polish Aikido Organization"),
                    "EN contact must lead with the Gdynia dojo, not the organization data"
  end

  def test_contact_quick_actions_call_write_directions
    [CONTACT_PL, CONTACT_EN].each do |relative|
      html = read(relative)
      actions = html[/<div class="quick-actions">.*?<\/div>/m]
      refute_nil actions, "#{relative}: quick-action block must exist in the Gdynia section"

      tel = actions[/href="tel:([^"]+)"/, 1]
      refute_nil tel, "#{relative}: quick actions must contain a tel: link"
      assert_match(/\A\+\d+\z/, tel, "#{relative}: tel: link must be the full number, not masked")
      assert_includes actions, "href=\"mailto:contact@aikido-polska.eu\"",
                      "#{relative}: quick actions must contain the write (mailto) link"
      assert_includes actions, "href=\"#{DIRECTIONS}\"",
                      "#{relative}: directions link must point at the confirmed dojo coordinates"
    end
  end

  def test_contact_map_embed_matches_confirmed_coordinates
    [CONTACT_PL, CONTACT_EN].each do |relative|
      html = read(relative)
      iframe = html[/<iframe[^>]*>/m]
      refute_nil iframe, "#{relative}: map iframe must exist"
      assert_match(/18\.543213\d+/, iframe, "#{relative}: map must use confirmed longitude")
      assert_match(/54\.544176\d+/, iframe, "#{relative}: map must use confirmed latitude")
    end
  end

  def test_contact_raciborz_is_seat_not_training_hall
    pl = read(CONTACT_PL)
    assert_includes pl, "siedziba", "PL contact must label Raciborz as the seat"
    assert_includes pl, "zajęcia zawieszone", "PL contact must keep the Raciborz class-suspended status"

    en = read(CONTACT_EN)
    assert_includes en, "headquarters", "EN contact must label Raciborz as the headquarters"
    assert_includes en, "suspended", "EN contact must keep the Raciborz class-suspended status"
  end

  def test_contact_lead_is_short_not_a_link_farm
    [CONTACT_PL, CONTACT_EN].each do |relative|
      html = read(relative)
      lead = html[/<p class="lead">.*?<\/p>/m]
      refute_nil lead, "#{relative}: lead paragraph must exist"
      links = lead.scan(/<a\s/).length
      assert_operator links, :<=, 2, "#{relative}: lead must not be a link farm (found #{links} links)"
    end
  end

  def test_contact_adds_no_data_collecting_form
    [CONTACT_PL, CONTACT_EN].each do |relative|
      refute_match(/<form\b/i, read(relative), "#{relative}: no data-collecting form may be added")
    end
  end

  def test_start_card_on_gdynia_training_first_class_pages
    START_PAGES.each do |relative, expected|
      html = read(relative)
      card = html[/<aside class="quick-start".*?<\/aside>/m]
      refute_nil card, "#{relative}: concise start card must exist right after the lead"
      assert_includes card, expected[:schedule], "#{relative}: start card must state training hours"
      assert_includes card, "Grudzi", "#{relative}: start card must state the dojo address"
      assert_includes card, "href=\"#{expected[:contact]}\"",
                      "#{relative}: start card must link the contact/schedule page"
    end
  end

  def test_quick_action_targets_meet_touch_size_in_css
    css = read("assets/style.css")
    block = css[/\.quick-action\s*\{.*?\}/m]
    refute_nil block, "style.css must style .quick-action"
    assert_match(/min-height:\s*44px/, block, ".quick-action targets must be at least 44px tall")
  end
end

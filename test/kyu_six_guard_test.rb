require_relative "test_helper"

# Guard test (t_4f15ee16): 6 kyu must stay present in kyu requirements templates
# and SEO snapshot. This blocks any future commit (manual, cron, or AI-driven)
# that accidentally removes the section as happened in a7cbd540.
class KyuSixGuardTest < Minitest::Test
  def site_root
    Site::Container.config.root
  end

  def test_pl_kyu_template_contains_6kyu_section
    pl = File.read(site_root.join("templates/wymagania_egzaminacyjne_kyu.html.erb"))

    assert_includes pl, '<li><a href="#6kyu">6 kyu</a></li>',
                    "PL kyu template must include 6kyu navigation link"
    assert_includes pl, '<h2 id="6kyu">',
                    "PL kyu template must include 6kyu heading"
    assert_includes pl, "od zdobycia 7 kyu",
                    "6kyu must require prior 7 kyu"
  end

  def test_pl_kyu_5kyu_refers_to_6kyu_not_7kyu
    pl = File.read(site_root.join("templates/wymagania_egzaminacyjne_kyu.html.erb"))

    assert_includes pl, "od zdobycia 6 kyu",
                    "5 kyu must reference 6 kyu as prerequisite"
  end

  def test_en_kyu_template_contains_6kyu_section
    en = File.read(site_root.join("templates/wymagania_egzaminacyjne_kyu_en.html.erb"))

    assert_includes en, '<li><a href="#6kyu">6 kyu</a></li>',
                    "EN kyu template must include 6 kyu link"
    assert_includes en, '<h2 id="6kyu">',
                    "EN kyu template must include 6kyu heading"
    assert_includes en, "since obtaining 7 kyu",
                    "6kyu must require prior 7 kyu"
  end

  def test_seo_snapshot_has_6_kyu_not_7_kyu_as_minimum
    fixture = JSON.parse(File.read(
      File.expand_path("fixtures/seo_snapshot.json", __dir__)
    ))

    pl = fixture["wymagania_egzaminacyjne/kyu.html"]
    assert pl["description"].include?("6 kyu"),
           "PL SEO snapshot must reference 6 kyu (pre-a7cbd540 state)"
    refute pl["description"].include?("7 kyu do 1"),
           "PL SEO snapshot must NOT reference 7 kyu-to-1 as minimum"

    en = fixture["en/requirements/kyu.html"]
    assert en["description"].include?("6th Kyu"),
           "EN SEO snapshot must reference 6th Kyu"
    refute en["description"].include?("7th Kyu to 1st"),
           "EN SEO snapshot must NOT reference 7th Kyu-to-1st as minimum"
  end
end

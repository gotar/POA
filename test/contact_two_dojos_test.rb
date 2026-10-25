require_relative "test_helper"
require "open3"

class ContactTwoDojosTest < Minitest::Test
  RACIBORZ_DIRECTIONS = "https://www.google.com/maps/dir/?api=1&amp;destination=Zesp%C3%B3%C5%82+Szkolno-Przedszkolny+Nr+6%2C+ul.+Juliusza+S%C5%82owackiego+48%2C+Racib%C3%B3rz".freeze

  def setup
    @output = Dir.mktmpdir("poa-contact-two-dojos-")
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

  def rendered(path)
    File.read(File.join(@output, path))
  end

  def section_for(html, heading)
    start = html.index(heading)
    refute_nil start, "missing section heading #{heading.inspect}"
    following = html.index('<div class="contact-section">', start + heading.length)
    html[start...(following || html.length)]
  end

  def test_rendered_contact_pages_keep_complete_details_within_their_dojo_sections
    {
      "kontakt.html" => {
        gdynia_heading: "Sesshinkan Dojo Gdynia — treningi",
        gdynia: ["Poniedziałek", "Piątek", "20:00", "Grudzińskiego 1", "Sensei Oskar Szrajer 5 dan", "tel:+48608019078", "destination=54.5441767,18.5432137"],
        raciborz_heading: "Dojo Racibórz — treningi",
        raciborz: ["Środy, 17:30–19:30", "Zespół Szkolno-Przedszkolny Nr 6", "Słowackiego 48", "Sensei Krzysztof Seget", "tel:+48724940651", RACIBORZ_DIRECTIONS]
      },
      "en/contact.html" => {
        gdynia_heading: "Sesshinkan Dojo Gdynia — training",
        gdynia: ["Monday", "Friday", "8:00 PM", "Grudzińskiego 1", "Sensei Oskar Szrajer 5 dan", "tel:+48608019078", "destination=54.5441767,18.5432137"],
        raciborz_heading: "Racibórz Dojo — training",
        raciborz: ["Wednesdays, 17:30–19:30", "Zespół Szkolno-Przedszkolny Nr 6", "Słowackiego 48", "Sensei Krzysztof Seget", "tel:+48724940651", RACIBORZ_DIRECTIONS]
      }
    }.each do |path, expected|
      html = rendered(path)
      gdynia = section_for(html, expected[:gdynia_heading])
      expected[:gdynia].each { |fact| assert_includes gdynia, fact, "#{path}: Gdynia section missing #{fact}" }
      raciborz = section_for(html, expected[:raciborz_heading])
      expected[:raciborz].each { |fact| assert_includes raciborz, fact, "#{path}: Racibórz section missing #{fact}" }
    end
  end

  def test_rendered_first_training_pages_include_full_raciborz_pointer
    ["pierwszy-trening-aikido-gdynia.html", "en/first-aikido-training-gdynia.html"].each do |path|
      html = rendered(path)
      heading = path.start_with?("en/") ? "Racibórz Dojo" : "Dojo Racibórz"
      start = html.index(heading)
      refute_nil start, "#{path}: Racibórz section heading missing"
      block_end = html.index("</section>", start)
      refute_nil block_end, "#{path}: Racibórz section end missing"
      raciborz = html[start...block_end]
      ["17:30", "Słowackiego 48", "Sensei Krzysztof Seget", "tel:+48724940651", path.start_with?("en/") ? "/en/raciborz.html" : "/raciborz.html"].each do |fact|
        assert_includes raciborz, fact, "#{path}: Racibórz pointer missing #{fact}"
      end
    end
  end
end

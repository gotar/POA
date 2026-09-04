require_relative "test_helper"
require "open3"

# Portraits in the biographies carry historical context. Keep their localized
# alternatives in the rendered pages so image-only users receive that context.
class BiographyImageAccessibilityTest < Minitest::Test
  TOYODA_IMAGES = {
    "biografie/toyoda.html" => [
      ["/assets/images/toyoda/young_toyoda.jpg", "Młody Fumio Toyoda"],
      ["/assets/images/toyoda/toyoda.jpg", "Shihan Fumio Toyoda"],
      ["/assets/images/toyoda/older_toyoda.jpg", "Shihan Fumio Toyoda w późniejszych latach"]
    ],
    "en/biographies/toyoda.html" => [
      ["/assets/images/toyoda/young_toyoda.jpg", "Young Fumio Toyoda"],
      ["/assets/images/toyoda/toyoda.jpg", "Shihan Fumio Toyoda"],
      ["/assets/images/toyoda/older_toyoda.jpg", "Shihan Fumio Toyoda in later years"]
    ]
  }.freeze

  GERMANOV_IMAGES = {
    "biografie/germanov.html" => [
      ["/assets/images/germanov/germanov.jpg", "Shihan Edward Germanov"],
      ["/assets/images/germanov/germanov2.jpg", "Shihan Edward Germanov podczas treningu aikido"]
    ],
    "en/biographies/germanov.html" => [
      ["/assets/images/germanov/germanov.jpg", "Shihan Edward Germanov"],
      ["/assets/images/germanov/germanov2.jpg", "Shihan Edward Germanov during an aikido training session"]
    ]
  }.freeze

  OSENSEI_IMAGES = {
    "biografie/o-sensei.html" => [
      ["/assets/images/ueshiba/young_ueshiba.jpg", "Młody Morihei Ueshiba"],
      ["/assets/images/ueshiba/ueshiba.jpg", "Morihei Ueshiba, założyciel aikido"],
      ["/assets/images/ueshiba/older_ueshiba.jpg", "Morihei Ueshiba w okresie iwama"]
    ],
    "en/biographies/o-sensei.html" => [
      ["/assets/images/ueshiba/young_ueshiba.jpg", "Young Morihei Ueshiba"],
      ["/assets/images/ueshiba/ueshiba.jpg", "Morihei Ueshiba, founder of aikido"],
      ["/assets/images/ueshiba/older_ueshiba.jpg", "Morihei Ueshiba in his later years in Iwama"]
    ]
  }.freeze

  def test_biographies_render_localized_alternative_text_for_portraits
    Dir.mktmpdir("poa-bio-image-alt-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )

      assert status.success?, "expected build to pass:\n#{output}"

      [TOYODA_IMAGES, GERMANOV_IMAGES, OSENSEI_IMAGES].each do |images_by_path|
        images_by_path.each do |path, images|
          html = File.read(File.join(export_dir, path))

          images.each do |src, alt|
            # The localized alt text is the accessibility contract. `loading="lazy"`
            # is a performance hint that may be added by a separate optimization.
            expected_image = %(<img src="#{src}" alt="#{alt}")
            assert_includes html, expected_image, "#{path} must describe #{src} in its page language"
          end
        end
      end
    end
  end
end

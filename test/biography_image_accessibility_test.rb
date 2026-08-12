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

  def test_toyoda_biographies_render_localized_alternative_text_for_portraits
    Dir.mktmpdir("poa-toyoda-image-alt-") do |export_dir|
      output, status = Open3.capture2e(
        { "EXPORT_DIR" => export_dir },
        File.join(site_root, "bin/build"),
        chdir: site_root.to_s
      )

      assert status.success?, "expected build to pass:\n#{output}"

      TOYODA_IMAGES.each do |path, images|
        html = File.read(File.join(export_dir, path))

        images.each do |src, alt|
          expected_image = %(<img src="#{src}" alt="#{alt}">)
          assert_includes html, expected_image, "#{path} must describe #{src} in its page language"
        end
      end
    end
  end
end
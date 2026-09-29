require_relative "test_helper"

# UIUX-01 (t_ce38bed9): the contact phone links shipped a masked href
# (tel:+486****9078) while showing the full number. A masked tel: URI is a
# dead end on mobile — the dialer gets asterisks instead of digits.
#
# This test enforces text/href consistency: every tel: link in every template
# must carry a digits-only URI (RFC 3966 global-number-digits) whose digit
# sequence matches the visible number, and no tel: URI may contain masking
# characters. Localized aria-label/title and the visible format are asserted
# so a fix cannot silently drop them.
class ContactPhoneLinksTest < Minitest::Test
  TEL_LINK = /<a\b[^>]*href="tel:([^"]+)"[^>]*>(.*?)<\/a>/m.freeze

  EXPECTED = {
    "templates/kontakt.html.erb" => {
      uri: "+48608019078",
      text: "+48 608-019-078",
      label: "Zadzwoń pod +48 608-019-078"
    },
    "templates/contact_en.html.erb" => {
      uri: "+48608019078",
      text: "+48 608-019-078",
      label: "Call +48 608-019-078"
    }
  }.freeze

  def template_sources
    Dir[site_root.join("templates/**/*.erb").to_s].sort
  end

  def test_no_masked_tel_uri_in_any_template
    masked = []
    template_sources.each do |file|
      File.read(file).scan(/href="tel:([^"]+)"/).flatten.each do |uri|
        masked << "#{file.sub("#{site_root}/", "")}: tel:#{uri}" if uri.match?(/[^+\d]/)
      end
    end
    assert_empty masked, "masked tel: URIs must not ship:\n#{masked.join("\n")}"
  end

  def test_contact_phone_link_text_matches_tel_uri
    EXPECTED.each do |relative, expected|
      html = File.read(site_root.join(relative).to_s)
      links = html.scan(TEL_LINK)
      assert_equal 1, links.length, "#{relative}: expected exactly one tel: link"

      uri, text = links.first
      assert_equal expected[:uri], uri, "#{relative}: tel: URI must be the full number"
      assert_equal expected[:text], text.strip, "#{relative}: visible format must be preserved"

      uri_digits = uri.sub(/\A\+/, "").gsub(/\D/, "")
      text_digits = text.gsub(/\D/, "")
      assert_equal text_digits, uri_digits, "#{relative}: tel: digits must match visible digits"

      assert_includes html, %(aria-label="#{expected[:label]}"), "#{relative}: localized aria-label"
      assert_includes html, %(title="#{expected[:label]}"), "#{relative}: localized title"
    end
  end

  def test_contact_phone_link_is_keyboard_focusable_native_anchor
    EXPECTED.each_key do |relative|
      html = File.read(site_root.join(relative).to_s)
      anchor = html[TEL_LINK, 0]
      refute_nil anchor, "#{relative}: phone must be a native <a> element"
      refute_match(/tabindex="-1"/, anchor, "#{relative}: phone link must stay in tab order")
    end
  end
end

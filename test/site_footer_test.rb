require_relative "test_helper"
require "open3"

# UIUX-11 (t_cb0aa45d): one shared semantic footer (contentinfo landmark) on
# every rendered page. Behavioral contract — not selector presence:
#   - exactly one <footer class="site-footer"> per page, rendered after </main>
#     and before </body> (closes long contact/article/FAQ pages with a clear
#     next action);
#   - PL footer carries org identity, Gdynia address/schedule, full-digit
#     tel: that matches the visible number, mailto, directions link, the
#     free-first-training CTA and shortcuts to existing pages only (the
#     InternalLinksTest oracle re-checks every href);
#   - organization data stays short: KRS in one line + link to the full
#     contact page, no IBAN/NIP/Regon dump and no dynamic copyright year
#     (deterministic build — no clock);
#   - EN footer is the localized equivalent with /en/ targets;
#   - footer CTA tap target >= 44px, footer navs are not sticky and not part
#     of the header auto-hide (header auto-hide targets the first <nav> only).
class SiteFooterTest < Minitest::Test
  PL_PAGES = %w[index.html kontakt.html gdynia.html blog.html faq.html].freeze
  EN_PAGES = %w[en/index.html en/contact.html en/gdynia.html en/blog.html en/faq.html].freeze

  FOOTER_OPEN = '<footer class="site-footer">'.freeze
  FOOTER_CLOSE = "</footer>".freeze

  def build_once
    @build_once ||= begin
      dir = Dir.mktmpdir("poa-footer-")
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

  def rendered(path)
    File.read(File.join(build_once, path))
  end

  def test_every_page_has_exactly_one_footer_landmark_after_main
    (PL_PAGES + EN_PAGES).each do |path|
      html = rendered(path)
      assert_equal 1, html.scan(FOOTER_OPEN).size, "#{path}: exactly one footer landmark"
      assert_equal 1, html.scan(FOOTER_CLOSE).size, "#{path}: footer properly closed"
      assert_operator html.index(FOOTER_OPEN), :>, html.index("</main>"),
        "#{path}: footer must come after main content"
      assert_operator html.index(FOOTER_OPEN), :<, html.index("</body>"),
        "#{path}: footer must sit before </body>"
    end
  end

  def test_pl_footer_identity_address_and_schedule
    html = rendered("index.html")
    assert_includes html, "Polska Organizacja Aikido"
    assert_includes html, "Sesshinkan Dojo — Gdynia"
    assert_includes html, "ul. Komandora Podporucznika Jana Grudzińskiego 1"
    assert_includes html, "81-103 Gdynia"
    assert_includes html, "poniedziałek i piątek 20:00–21:30"
    assert_includes html, "Pierwszy trening bezpłatny (wiek min. 12–13 lat)"
  end

  def test_pl_footer_cta_and_shortcuts_resolve_to_rendered_pages
    html = rendered("index.html")
    footer = html[/<footer class="site-footer">.*<\/footer>/m]

    %w[
      /gdynia.html /treningi-aikido-gdynia.html /pierwszy-trening-aikido-gdynia.html
      /blog.html /aikido/dla_poczatkujacych.html /wymagania_egzaminacyjne/kyu.html
      /wymagania_egzaminacyjne/dan.html /slowniczek.html /faq.html /kontakt.html
    ].each do |href|
      assert_includes footer, %(href="#{href}"), "PL footer must link #{href}"
    end
    assert_includes footer, "Bezpłatny pierwszy trening — jak zacząć",
      "PL footer must close with the free-first-training CTA"
    assert_includes footer, "pełne dane organizacji",
      "PL footer must point to the full organization data page"
  end

  def test_pl_footer_tel_is_full_digits_matching_visible_text
    footer = rendered("index.html")[/<footer class="site-footer">.*<\/footer>/m]
    tel_links = footer.scan(/<a [^>]*href="tel:([^"]+)"[^>]*>(.*?)<\/a>/m)
    refute_empty tel_links, "PL footer must expose a phone link"

    tel_links.each do |uri, text|
      refute_match(/[^+\d]/, uri, "PL footer tel: URI must carry full digits, got #{uri.inspect}")
      uri_digits = uri.delete("^0-9")
      text_digits = text.delete("^0-9")
      assert_equal text_digits, uri_digits, "PL footer tel digits must match visible digits"
    end

    assert_includes footer, 'aria-label="Zadzwoń: +48 608-019-078"'
    assert_includes footer, 'title="Zadzwoń: +48 608-019-078"'
  end

  def test_pl_footer_keeps_organization_data_short_without_year
    footer = rendered("index.html")[/<footer class="site-footer">.*<\/footer>/m]

    assert_includes footer, "KRS 0000296914"
    %w[IBAN Regon NIP].each do |field|
      refute_includes footer, field, "PL footer must not dump the #{field} block"
    end
    refute_match(/©\s*\d{4}/, footer, "PL footer must not render a dynamic copyright year")
  end

  def test_en_footer_is_localized_equivalent
    html = rendered("en/index.html")
    footer = html[/<footer class="site-footer">.*<\/footer>/m]

    assert_includes footer, "Polish Aikido Organization"
    assert_includes footer, "Sesshinkan Dojo — Gdynia"
    assert_includes footer, "Monday and Friday 8:00 PM–9:30 PM"
    assert_includes footer, "First class free (minimum age 12–13)"

    %w[
      /en/gdynia.html /en/aikido-training-gdynia.html /en/first-aikido-training-gdynia.html
      /en/blog.html /en/aikido/beginners.html /en/requirements/kyu.html
      /en/requirements/dan.html /en/glossary.html /en/faq.html /en/contact.html
    ].each do |href|
      assert_includes footer, %(href="#{href}"), "EN footer must link #{href}"
    end
    assert_includes footer, "Free first class — how to start"
    assert_includes footer, "full organization details"
    assert_includes footer, 'aria-label="Call: +48 608-019-078"'
    refute_match(/©\s*\d{4}/, footer, "EN footer must not render a dynamic copyright year")
    %w[IBAN Regon NIP].each do |field|
      refute_includes footer, field, "EN footer must not dump the #{field} block"
    end
  end

  def test_footer_cta_meets_minimum_tap_target_and_footer_nav_is_not_sticky
    css = File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")

    cta_blocks = css.scan(/^\.site-footer \.footer-cta \{([^{}]*)\}/m).flatten
    refute_empty cta_blocks, "expected a base .site-footer .footer-cta rule"
    cta_heights = cta_blocks.map { |rules| rules[/min-height:\s*(?<px>\d+)px/m, :px]&.to_i }
    assert cta_heights.any? { |px| !px.nil? && px >= 44 },
      "expected .footer-cta to guarantee a >=44px tap target, got #{cta_heights.inspect}"

    assert_includes cta_blocks.join, "color: #ffffff;",
      ".footer-cta white text must survive the .site-footer a cascade"

    nav_overrides = css.scan(/^\.site-footer nav \{([^{}]*)\}/m).flatten.join
    assert_includes nav_overrides, "position: static;",
      "footer navs must not inherit the sticky header treatment"
    assert_includes nav_overrides, "background: transparent;"
  end

  def test_header_auto_hide_never_targets_the_footer
    script = File.read(site_root.join("assets/app.js"))
    assert_includes script, "const nav = document.querySelector('nav');",
      "header auto-hide must target the first nav only"
    refute_includes script, ".site-footer",
      "header auto-hide must not reach into the footer"
  end

  def test_blog_article_pages_close_with_the_shared_footer
    html = rendered("blog/czy-warto-cwiczyc-aikido.html")
    assert_includes html, FOOTER_OPEN
    assert_operator html.index(FOOTER_OPEN), :>, html.index("article-reader-footer"),
      "article reader footer (in-content) must precede the site footer"
  end

  def test_404_page_keeps_the_shared_footer
    html = rendered("404.html")
    assert_includes html, FOOTER_OPEN
    assert_operator html.index(FOOTER_OPEN), :>, html.index("404 — nie znaleziono strony"),
      "404 content must precede the shared footer"
  end
end
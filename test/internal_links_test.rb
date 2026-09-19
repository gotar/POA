require_relative "test_helper"

# Every static same-site link baked into a template must resolve to a page the
# generator actually renders (or a static file it actually copies). Two dead
# links shipped unnoticed (t_78f0c50e: /korzysci.html in gdynia.html.erb and
# /en/toyoda.html in blog/styl_toyody_en.html.erb) — this test is the oracle
# that would have caught them.
#
# Scope notes:
# - Only literal href="/..."/src="/..." attributes are checked. Dynamic
#   hrefs (<%= ... %>, e.g. the nav language switcher fed by LANG_URL_MAP)
#   are covered indirectly: every LANG_URL_MAP value must itself resolve.
# - External URLs, protocol-relative URLs, anchors, mailto: and tel: never
#   match the scan pattern and are out of scope.
class InternalLinksTest < Minitest::Test
  STATIC_LINK = /(?:href|src)="(\/[^\/\"#?][^\"#?]*)"/.freeze

  def known_pages
    pages = Site::Generate::PAGES.keys.dup
    context = Site::Container["view.context"]
    (1..context.blog_total_pages(language: "pl")).each do |n|
      pages << (n == 1 ? "blog.html" : "blog-#{n}.html")
    end
    (1..context.blog_total_pages(language: "en")).each do |n|
      pages << (n == 1 ? "en/blog.html" : "en/blog-#{n}.html")
    end
    pages
  end

  def static_links
    links = Hash.new { |h, k| h[k] = [] }
    Dir[site_root.join("templates/**/*.erb").to_s].sort.each do |file|
      File.read(file).scan(STATIC_LINK).flatten.each do |href|
        path = href.sub(%r{\?.*\z}, "")
        links[path] << file.sub("#{site_root}/", "")
      end
    end
    links
  end

  def page_link?(path)
    path.end_with?(".html") || path.end_with?("/")
  end

  def normalize_page_key(key)
    return "index.html" if key.empty?
    return "#{key}index.html" if key.end_with?("/")

    key
  end

  def page_target?(path)
    known_pages.include?(normalize_page_key(path.sub(%r{\A/}, "")))
  end

  def asset_target?(path)
    return true if File.file?(site_root.join(path.sub(%r{\A/}, "")).to_s)
    return true if File.file?(site_root.join("assets/favicons/#{File.basename(path)}").to_s)

    false
  end

  def test_every_static_page_link_resolves_to_a_rendered_page
    dead = static_links.select { |path, _| page_link?(path) }
                       .reject { |path, _| page_target?(path) }

    assert_empty dead,
                 "dead internal page links (no rendered target):\n" +
                 dead.map { |path, files| "  #{path} <- #{files.uniq.join(', ')}" }.join("\n")
  end

  def test_every_static_asset_link_resolves_to_a_copied_file
    missing = static_links.reject { |path, _| page_link?(path) }
                          .reject { |path, _| asset_target?(path) }

    assert_empty missing,
                 "internal asset links with no file under assets/ or assets/favicons/:\n" +
                 missing.map { |path, files| "  #{path} <- #{files.uniq.join(', ')}" }.join("\n")
  end

  def test_lang_url_map_points_at_rendered_pages_only
    map = Site::View::Context::LANG_URL_MAP

    bad_values = map.reject { |_, target| known_pages.include?(normalize_page_key(target)) }
    bad_keys = map.reject { |source, _| source.empty? || known_pages.include?(normalize_page_key(source)) }

    assert_empty bad_values, "LANG_URL_MAP targets with no rendered page: #{bad_values.inspect}"
    assert_empty bad_keys, "LANG_URL_MAP sources with no rendered page: #{bad_keys.inspect}"
  end
end

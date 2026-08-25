require "date"
require "site/view/context"

module Site
  # Generates sitemap.xml from the pages actually rendered during a build.
  #
  # The list of pages comes from Generate#render (every rendered path is
  # registered), so the sitemap can never drift out of sync with the site:
  # a page that is rendered is a page that is listed. Blog posts follow a
  # fixed convention (priority 0.7, changefreq monthly) and take their
  # lastmod from the publication dates already stored in
  # Site::View::Context::BLOG_POSTS_PL / _EN, so a new article gets its
  # sitemap entry automatically with no extra bookkeeping.
  #
  # Everything is derived from files committed to the repo — no git
  # invocation, no wall clock, no filesystem mtimes — so the build stays
  # fully deterministic across environments (worktree, container, CI).
  class Sitemap
    SITE_URL = "https://aikido-polska.eu"

    # Static page path => [priority, changefreq, lastmod], ported 1:1 from
    # the hand-maintained assets/sitemap.xml so existing conventions hold.
    # Anything not listed falls back to DEFAULT_META.
    META = {
      "/"                                => ["1.0", "weekly", "2026-03-06"],
      "/en/"                             => ["0.9", "weekly", "2026-03-06"],
      "/gdynia.html"                     => ["1.0", "monthly", "2026-01-30"],
      "/treningi-aikido-gdynia.html"     => ["0.9", "monthly", "2026-04-20"],
      "/pierwszy-trening-aikido-gdynia.html" => ["0.9", "monthly", "2026-04-20"],
      "/aikido-dla-doroslych-gdynia.html" => ["0.9", "monthly", "2026-04-20"],
      "/en/aikido-for-adults-gdynia.html" => ["0.9", "monthly", "2026-04-20"],
      "/en/gdynia.html"                  => ["0.9", "monthly", "2026-01-30"],
      "/kontakt.html"                    => ["0.9", "monthly", "2026-01-30"],
      "/en/contact.html"                 => ["0.9", "monthly", "2026-01-30"],
      "/aikido/czym_jest.html"           => ["0.8", "monthly", "2026-01-30"],
      "/en/aikido/what_is.html"          => ["0.8", "monthly", "2026-01-30"],
      "/aikido/dla_poczatkujacych.html"  => ["0.8", "monthly", "2026-01-30"],
      "/en/aikido/beginners.html"        => ["0.8", "monthly", "2026-01-30"],
      "/aikido/historia.html"            => ["0.7", "monthly", "2026-01-30"],
      "/en/aikido/history.html"          => ["0.7", "monthly", "2026-01-30"],
      "/aikido/korzysci.html"            => ["0.7", "monthly", "2026-01-30"],
      "/en/aikido/benefits.html"         => ["0.7", "monthly", "2026-01-30"],
      "/lineage.html"                    => ["0.7", "monthly", "2026-01-30"],
      "/en/lineage.html"                 => ["0.7", "monthly", "2026-01-30"],
      "/aikido/aiki_taiso.html"          => ["0.6", "monthly", "2026-01-30"],
      "/en/aikido/aiki_taiso.html"       => ["0.6", "monthly", "2026-01-30"],
      "/aikido/reishiki.html"            => ["0.6", "monthly", "2026-01-30"],
      "/en/aikido/reishiki.html"         => ["0.6", "monthly", "2026-01-30"],
      "/aikido/budo_zen.html"            => ["0.6", "monthly", "2026-02-08"],
      "/en/aikido/budo_zen.html"         => ["0.6", "monthly", "2026-02-08"],
      "/aikido/ki_kokyu.html"            => ["0.6", "monthly", "2026-02-09"],
      "/en/aikido/ki_kokyu.html"         => ["0.6", "monthly", "2026-02-09"],
      "/yudansha.html"                   => ["0.6", "monthly", "2026-01-30"],
      "/en/yudansha.html"                => ["0.6", "monthly", "2026-01-30"],
      "/wymagania_egzaminacyjne/kyu.html" => ["0.6", "monthly", "2026-01-30"],
      "/en/requirements/kyu.html"        => ["0.6", "monthly", "2026-01-30"],
      "/wymagania_egzaminacyjne/dan.html" => ["0.6", "monthly", "2026-01-30"],
      "/en/requirements/dan.html"        => ["0.6", "monthly", "2026-01-30"],
      "/biografie/toyoda.html"           => ["0.6", "monthly", "2026-01-30"],
      "/en/biographies/toyoda.html"      => ["0.6", "monthly", "2026-01-30"],
      "/biografie/o-sensei.html"         => ["0.6", "monthly", "2026-01-30"],
      "/en/biographies/o-sensei.html"    => ["0.6", "monthly", "2026-01-30"],
      "/biografie/germanov.html"         => ["0.6", "monthly", "2026-01-30"],
      "/en/biographies/germanov.html"    => ["0.6", "monthly", "2026-01-30"],
      "/biografie/ostrowski.html"        => ["0.6", "monthly", "2026-01-30"],
      "/en/biographies/ostrowski.html"   => ["0.6", "monthly", "2026-01-30"],
      "/biografie/szrajer.html"          => ["0.7", "monthly", "2026-04-20"],
      "/en/biographies/szrajer.html"     => ["0.7", "monthly", "2026-04-20"],
      "/biografie/kisshomaru.html"       => ["0.5", "monthly", "2026-01-30"],
      "/en/biographies/kisshomaru.html"  => ["0.5", "monthly", "2026-01-30"],
      "/biografie/moriteru.html"         => ["0.5", "monthly", "2026-01-30"],
      "/en/biographies/moriteru.html"    => ["0.5", "monthly", "2026-01-30"],
      "/biografie/mitsuteru.html"        => ["0.5", "monthly", "2026-01-30"],
      "/en/biographies/mitsuteru.html"   => ["0.5", "monthly", "2026-01-30"],
      "/slowniczek.html"                 => ["0.5", "monthly", "2026-01-30"],
      "/en/glossary.html"                => ["0.5", "monthly", "2026-01-30"],
      "/wydarzenia/2026.html"            => ["0.8", "weekly", "2026-01-30"],
      "/en/events/2026.html"             => ["0.8", "weekly", "2026-01-30"],
      "/faq.html"                        => ["0.8", "monthly", "2026-01-30"],
      "/en/faq.html"                     => ["0.8", "monthly", "2026-01-30"]
    }.freeze

    DEFAULT_META = ["0.6", "monthly", nil].freeze
    BLOG_META = ["0.7", "monthly"].freeze
    BLOG_INDEX_META = ["0.8", "weekly"].freeze
    BLOG_INDEX_PAGE_META = ["0.6", "weekly"].freeze

    # Pages that are rendered but must NOT appear in sitemap.xml.
    EXCLUDED = ["/404.html"].freeze

    # Polish month names (nominative) => month number, for parsing the
    # human-readable dates stored in BLOG_POSTS_PL (e.g. "13 czerwca 2026").
    PL_MONTHS = {
      "stycznia" => 1, "lutego" => 2, "marca" => 3, "kwietnia" => 4,
      "maja" => 5, "czerwca" => 6, "lipca" => 7, "sierpnia" => 8,
      "września" => 9, "października" => 10, "listopada" => 11, "grudnia" => 12
    }.freeze

    # pages: array of [path, view] pairs collected from Generate#render
    def call(pages)
      entries = pages.reject { |path, _view| excluded?(path) }
                     .map { |path, _view| entry_for(path) }
      entries.sort_by! { |e| e[:loc] }

      body = entries.map { |e| url_xml(e) }.join("\n")
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        #{body}
        </urlset>
      XML
    end

    private

    def excluded?(path)
      url_path = path.empty? ? "/" : "/#{path}"
      EXCLUDED.include?(url_path)
    end

    def entry_for(path)
      url_path = if path.empty?
        "/"
      elsif path.end_with?(".html")
        "/#{path}"
      else
        "/#{path}/" # directory index (e.g. "en" -> "/en/")
      end

      {
        loc: "#{SITE_URL}#{url_path}",
        priority: priority_for(url_path),
        changefreq: changefreq_for(url_path),
        lastmod: lastmod_for(url_path)
      }
    end

    def priority_for(url_path)
      return BLOG_INDEX_PAGE_META[0] if blog_index_page_path?(url_path)
      return BLOG_INDEX_META[0] if blog_index_path?(url_path)
      return BLOG_META[0] if blog_post_path?(url_path)

      (META[url_path] || DEFAULT_META)[0]
    end

    def changefreq_for(url_path)
      return BLOG_INDEX_PAGE_META[1] if blog_index_page_path?(url_path)
      return BLOG_INDEX_META[1] if blog_index_path?(url_path)
      return BLOG_META[1] if blog_post_path?(url_path)

      (META[url_path] || DEFAULT_META)[1]
    end

    def lastmod_for(url_path)
      return blog_lastmod(url_path) if blog_post_path?(url_path)
      return blog_index_lastmod(url_path) if blog_index_path?(url_path) || blog_index_page_path?(url_path)

      (META[url_path] || DEFAULT_META)[2]
    end

    # Blog index pages: lastmod = date of the newest post shown on that page,
    # so the index automatically stays fresh whenever a post is published.
    def blog_index_lastmod(url_path)
      english = url_path.start_with?("/en/")
      posts = english ? Site::View::Context::BLOG_POSTS_EN : Site::View::Context::BLOG_POSTS_PL

      if (m = url_path.match(%r{\A/(?:en/)?blog(?:-(\d+))?\.html\z}))
        page = (m[1] || "1").to_i
        per_page = Site::View::Context::BLOG_POSTS_PER_PAGE
        page_posts = posts.slice((page - 1) * per_page, per_page) || []
        newest = page_posts.first
        return nil unless newest && newest[:date]

        return parse_blog_date(newest[:date])
      end

      nil
    end

    def blog_lastmod(url_path)
      post = blog_posts.find { |p| p[:url] == url_path }
      return nil unless post && post[:date]

      parse_blog_date(post[:date])
    end

    def blog_posts
      @blog_posts ||= Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN
    end

    def parse_blog_date(text)
      if (m = text.match(/\A(\d{1,2})\s+([a-ząęóśłżźćń]+)\s+(\d{4})\z/i))
        day = m[1].to_i
        month = PL_MONTHS[m[2].downcase]
        return format("%04d-%02d-%02d", m[3].to_i, month, day) if month
      end

      Date.parse(text).strftime("%Y-%m-%d")
    rescue Date::Error, ArgumentError
      nil
    end

    def blog_post_path?(url_path)
      url_path.start_with?("/blog/", "/en/blog/")
    end

    def blog_index_path?(url_path)
      url_path == "/blog.html" || url_path == "/en/blog.html"
    end

    def blog_index_page_path?(url_path)
      url_path.match?(%r{\A/(?:en/)?blog-\d+\.html\z})
    end

    def url_xml(entry)
      lastmod = entry[:lastmod] ? "\n    <lastmod>#{entry[:lastmod]}</lastmod>" : ""
      <<~URL.chomp
          <url>
            <loc>#{entry[:loc]}</loc>
            <priority>#{entry[:priority]}</priority>
            <changefreq>#{entry[:changefreq]}</changefreq>#{lastmod}
          </url>
      URL
    end
  end
end

require_relative "test_helper"

class SocialPreviewTest < Minitest::Test
  CASES = {
    "index.html" => ["images/social/poa-share.png", "image/png", 1200, 630],
    "en/index.html" => ["images/social/poa-share.png", "image/png", 1200, 630],
    "blog/ma-ai-dystans-ktory-decyduje.html" => ["images/social/poa-share.png", "image/png", 1200, 630],
    "en/blog/ma-ai-the-distance-that-decides.html" => ["images/social/poa-share.png", "image/png", 1200, 630],
    "blog/enso-krag-obecnosci.html" => ["images/blog/enso-featured.png", "image/png", 1200, 686],
    "en/blog/enso-circle-of-presence.html" => ["images/blog/enso-featured.png", "image/png", 1200, 686],
    "blog/jeden-nauczyciel-jeden-przekaz.html" => ["images/blog/one-teacher-one-transmission-featured.jpeg", "image/jpeg", 1200, 630],
    "en/blog/one-teacher-one-transmission.html" => ["images/blog/one-teacher-one-transmission-featured.jpeg", "image/jpeg", 1200, 630]
  }.freeze

  def render_page(path)
    Site::Container["views.blog"]
    Site::Container["views.en.blog"]
    view = Site::Generate::PAGES.fetch(path)
    Site::Container[view].(context: make_context(current_path: path, root: site_root)).to_s
  end

  def meta(html, key)
    html.scan(/<meta\s+[^>]*>/).each do |tag|
      next unless tag.include?(%(property="#{key}")) || tag.include?(%(name="#{key}"))

      return CGI.unescapeHTML(tag[/content="([^"]*)"/, 1].to_s)
    end
    nil
  end

  def test_open_graph_and_twitter_use_existing_raster_images_with_correct_metadata
    CASES.each do |path, (asset, type, width, height)|
      html = render_page(path)
      url = "https://aikido-polska.eu/assets/#{asset}"
      assert_equal url, meta(html, "og:image"), path
      assert_equal url, meta(html, "og:image:secure_url"), path
      assert_equal url, meta(html, "twitter:image"), path
      assert_equal type, meta(html, "og:image:type"), path
      assert_equal width.to_s, meta(html, "og:image:width"), path
      assert_equal height.to_s, meta(html, "og:image:height"), path
      refute_empty meta(html, "og:image:alt").to_s, path
      assert_equal meta(html, "og:image:alt"), meta(html, "twitter:image:alt"), path

      file = site_root.join("assets", asset)
      assert file.file?, "#{path}: missing image #{asset}"
      data = file.binread
      if type == "image/png"
        assert_equal "\x89PNG\r\n\x1a\n".b, data.byteslice(0, 8), asset
        assert_equal [width, height], data.byteslice(16, 8).unpack("NN"), asset
      else
        assert_equal "\xff\xd8".b, data.byteslice(0, 2), asset
      end
      assert_operator file.size, :<, 300_000, "#{asset}: keep previews lightweight"
    end
  end

  def test_article_title_and_description_are_available_without_javascript
    {
      "blog/ma-ai-dystans-ktory-decyduje.html" => Site::View::Context::BLOG_POSTS_PL,
      "en/blog/ma-ai-the-distance-that-decides.html" => Site::View::Context::BLOG_POSTS_EN
    }.each do |path, posts|
      post = posts.find { |entry| entry[:url] == "/#{path}" }
      html = render_page(path)
      assert_equal post[:title], meta(html, "og:title"), path
      assert_equal post[:summary], meta(html, "og:description"), path
      assert_equal "https://aikido-polska.eu/#{path}", meta(html, "og:url"), path
      assert_equal "article", meta(html, "og:type"), path
    end
  end

  def test_english_root_uses_english_image_alt_after_generator_normalization
    expected = "Polska Organizacja Aikido — Aikido and Budō"
    assert_equal expected, make_context(current_path: "en").page_social_image_alt
    assert_equal expected, make_context(current_path: "en/index.html").page_social_image_alt
  end

  def test_entire_blog_catalog_uses_a_supported_existing_social_image
    (Site::View::Context::BLOG_POSTS_PL + Site::View::Context::BLOG_POSTS_EN).each do |post|
      asset = make_context.social_image_for_path(post[:url].delete_prefix("/"))
      assert_match(/\.(?:png|jpe?g)\z/, asset, post[:url])
      assert site_root.join("assets", asset).file?, post[:url]
    end
  end
end

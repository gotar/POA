require_relative "test_helper"

# UIUX-05: long-form reading typography with real Lato faces.
#
# The audit found Mui at 16px/1.5 in an 800px left-hugging column while the
# stylesheet asked for Lato 500/600/700 + italic — faces Google Fonts never
# served (old css?family=Lato URL loads 400 normal only), so every emphasis
# was faux-synthesized. These tests pin the contract: only weights we really
# load may be declared, the reading column keeps 18px/1.65-1.75 on a 65-75ch
# centered measure, headings scale fluidly, and metadata stays >= 14px.
class ReadingTypographyTest < Minitest::Test
  LOADED_WEIGHTS = %w[400 700].freeze
  NAMED_WEIGHTS = { "normal" => "400", "bold" => "700" }.freeze
  BASE_PX = 16

  def stripped_css
    File.read(site_root.join("assets/style.css")).gsub(%r{/\*.*?\*/}m, "")
  end

  def declarations_for(selector)
    stripped_css.scan(/#{Regexp.escape(selector)} \{(.*?)\}/m).flatten
  end

  def font_href_for(layout)
    html = File.read(site_root.join("templates/layouts/#{layout}.html.erb"))
    html[%r{<link href="(?<url>https://fonts\.googleapis\.com/[^"]+)"}, :url]
  end

  def test_layouts_load_real_lato_weights_with_italic_and_swap
    %w[site site_en].each do |layout|
      url = font_href_for(layout)
      refute_nil url, "#{layout} must load Lato from Google Fonts"

      assert_includes url, "css2?", "#{layout}: old css v1 API loads 400 normal only"
      assert_includes url, "family=Lato:", "#{layout} must pin explicit Lato axes"
      assert_includes url, "ital", "#{layout} must load real italics (em/cite were synthesized)"
      LOADED_WEIGHTS.each do |weight|
        assert_includes url, weight, "#{layout} must load Lato #{weight}"
      end
      assert_includes url, "display=swap", "#{layout} must keep display=swap"
      refute_match(/Noto|CJK|JP/, url, "#{layout} must not pull a heavy CJK webfont")
      refute_includes url, "css?family=Lato&", "#{layout} must drop the v1 URL"
    end
  end

  def test_every_declared_weight_resolves_to_a_loaded_face
    offenders = stripped_css.scan(/font-weight:\s*(?<w>[a-z0-9]+)\s*;/i)
      .flatten.map(&:downcase).uniq
      .reject { |w| LOADED_WEIGHTS.include?(w) || NAMED_WEIGHTS.key?(w) || w == "inherit" }

    assert_empty offenders,
      "these weights have no loaded Lato face (500/600 synthesize faux-bold): #{offenders.join(", ")}"
  end

  def test_article_reading_measure_and_rhythm
    blocks = declarations_for(".article")
    refute_empty blocks, "expected a .article reading-column rule"
    rules = blocks.first

    measure = rules[/max-width:\s*(?<v>[0-9.]+)ch/, :v].to_f
    assert_operator measure, :>=, 65, ".article measure #{measure}ch is below the 65ch floor"
    assert_operator measure, :<=, 75, ".article measure #{measure}ch exceeds the 75ch ceiling"

    assert_includes rules, "margin-inline: auto",
      ".article must center the reading column instead of hugging the left edge"

    size = rules[/font-size:\s*(?<v>[0-9.]+)rem/, :v].to_f
    assert_in_delta 1.125, size, 0.001, ".article must start at 18px (1.125rem), got #{size}rem"

    height = rules[/line-height:\s*(?<v>[0-9.]+)/, :v].to_f
    assert_operator height, :>=, 1.65, ".article line-height #{height} is below 1.65"
    assert_operator height, :<=, 1.75, ".article line-height #{height} exceeds 1.75"
  end

  def test_article_headings_scale_fluidly
    %w[h1 h2 h3].each do |heading|
      blocks = declarations_for(".article #{heading}")
      refute_empty blocks, "expected a fluid .article #{heading} rule"
      assert_includes blocks.first, "clamp(",
        ".article #{heading} must scale fluidly instead of jumping at breakpoints"
    end
  end

  def test_mobile_reading_floor_stays_legible
    # Several .article blocks exist (base, mobile override, pre-existing
    # max-width guard); assert over their union.
    blocks = declarations_for(".article")
    assert_includes stripped_css, "@media only screen and (max-width: 768px)",
      "expected a <=768px media query"
    assert blocks.any? { |b| b.include?("font-size: 1.0625rem") },
      "a mobile .article rule must pin the 17px floor explicitly"
    assert blocks.any? { |b| b.include?("max-width: 100%") },
      "a mobile .article rule must keep the full-width guard (no overflow on 320px)"

    size_px = blocks.map { |b| b[/font-size:\s*(?<v>[0-9.]+)rem/, :v].to_f }.max * BASE_PX
    assert_operator size_px, :>=, 17, "mobile article text #{size_px}px is below the 17px floor"

    heights = blocks.map { |b| b[/line-height:\s*(?<v>[0-9.]+)/, :v].to_f }.reject(&:zero?)
    refute_empty heights, "mobile .article rules must set a line-height"
    assert heights.all? { |h| h >= 1.65 && h <= 1.75 },
      "mobile article line-heights #{heights.inspect} must stay in 1.65-1.75"
  end

  def test_metadata_stays_at_or_above_14px
    {
      ".news-meta" => "post dates",
      ".concept-hero-kicker" => "hero kickers"
    }.each do |selector, what|
      blocks = declarations_for(selector)
      refute_empty blocks, "expected a #{selector} rule (#{what})"
      size_px = blocks.first[/font-size:\s*(?<v>[0-9.]+)rem/, :v].to_f * BASE_PX
      assert_operator size_px, :>=, 14, "#{selector} (#{what}) is #{size_px}px, below the 14px metadata floor"
    end
  end

  def test_components_keep_their_own_scale_inside_articles
    css = stripped_css
    reset = css[/\.article \.news-list,\s*\.article \.news-card,\s*\.article nav\.pagination,\s*\.article table \{(?<rules>[^}]*)\}/m, :rules]
    refute_nil reset, "expected a component scale reset inside .article (blog list, cards, tables, pagination)"
    assert_includes reset, "font-size: 1rem",
      "cards/tables/pagination inside .article must stay at base size, not inherit 18px"
  end

  def test_body_stack_falls_back_to_system_cjk_without_a_webfont
    # "body {" also matches the html,body reset — take the block that owns
    # the font stack.
    rules = declarations_for("body").find { |b| b.include?("font-family:") }
    refute_nil rules, "body must declare an explicit font stack"
    stack = rules[/font-family:\s*(?<v>[^;]+);/m, :v]
    refute_nil stack, "body must declare an explicit font stack"

    first = stack.split(",").first.strip
    assert_equal '"Lato"', first, "Lato must stay first so Latin keeps the brand face"

    assert_match(/Noto Sans JP|Hiragino|Yu Gothic|Meiryo/, stack,
      "kanji/kana need named system CJK fallbacks (no synthesized tofu)")
  end
end

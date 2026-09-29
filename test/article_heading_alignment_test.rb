require_relative "test_helper"

# A page heading/preamble must belong to its reading column, not to the
# wider outer content shell. Browser checks validate actual x coordinates.
class ArticleHeadingAlignmentTest < Minitest::Test
  TEMPLATES = %w[
    faq faq_en gdynia gdynia_en historia historia_en korzysci korzysci_en
    czym_jest_aikido what_is_aikido_en
    aikido/reishiki aikido/reishiki_en aikido/aiki_taiso aikido/aiki_taiso_en
  ].freeze

  def test_title_and_intro_share_existing_article_wrapper
    TEMPLATES.each do |name|
      html = File.read(site_root.join("templates/#{name}.html.erb"))
      assert_match(/<div class="content">\s*<div class="article">\s*<h1>/, html,
        "#{name}: title/preamble must start inside the reading column")
      assert_equal 1, html.scan('<div class="article">').size,
        "#{name}: do not nest a second reading column"
      assert_equal 1, html.scan('<h1>').size, "#{name}: preserve the single page title"
    end
  end
end

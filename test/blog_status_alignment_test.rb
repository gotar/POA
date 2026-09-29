require_relative "test_helper"

class BlogStatusAlignmentTest < Minitest::Test
  def test_status_group_aligns_left_and_wraps
    css = File.read(site_root.join("assets/style.css"))
    status = css[/\.blog-discovery-status \{([^}]+)\}/m, 1]
    refute_nil status
    assert_includes status, "justify-content: flex-start"
    assert_includes status, "text-align: left"
    assert_includes status, "align-items: center"
    assert_includes status, "flex-wrap: wrap"
  end

  def test_counter_spacing_wins_over_content_paragraph_margin
    css = File.read(site_root.join("assets/style.css"))
    count = css[/\.blog-discovery-status \.blog-result-count \{([^}]+)\}/m, 1]
    refute_nil count, "a single-class rule loses to .content p and offsets the count vertically"
    assert_includes count, "margin: 0"
  end
end

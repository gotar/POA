require_relative "test_helper"

# Verifies the test harness itself: container boots, context instantiates.
class HarnessSmokeTest < Minitest::Test
  def test_container_boots_and_exposes_context_prototype
    prototype = Site::Container["view.context"]

    assert_instance_of Site::View::Context, prototype
    assert_instance_of Site::Generate, Site::Container["generate"]
  end

  def test_context_instantiates_with_test_settings
    ctx = make_context(current_path: "blog.html")

    assert_equal "Polska Organizacja Aikido", ctx.site_name
    assert_equal "blog.html", ctx.current_path
  end

  def test_settings_override_reaches_context
    ctx = make_context(current_path: "x.html", settings: settings(site_name: "Test Dojo"))

    assert_equal "Test Dojo", ctx.site_name
  end

  def test_page_title_defaults_to_site_name_for_unknown_path
    ctx = make_context(current_path: "nie-ma-takiej-strony.html")

    assert_equal "Polska Organizacja Aikido", ctx.page_title
  end
end

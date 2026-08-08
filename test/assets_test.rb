require_relative "test_helper"

# Regression tests for Site::Assets::Precompiled.
#
# Bug fixed: manifest.json was loaded with YAML.load_file (unsafe
# deserialization, wrong parser for a JSON file). It now goes through
# JSON.parse with a guard for a missing manifest file.
class AssetsPrecompiledTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir("poa-assets-")
    FileUtils.mkdir_p(File.join(@root, "assets"))
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def write_manifest(contents)
    File.write(File.join(@root, "assets", "manifest.json"), contents)
  end

  def test_returns_url_from_json_manifest
    write_manifest(%({"app.js": "app-8f3a2b1c9d.js", "style.css": "style-1234567890.css"}))

    precompiled = Site::Assets::Precompiled.new(@root)

    assert_equal "/assets/app-8f3a2b1c9d.js", precompiled["app.js"]
    assert_equal "/assets/style-1234567890.css", precompiled["style.css"]
  end

  def test_returns_nil_for_unknown_asset
    write_manifest(%({"app.js": "app-8f3a2b1c9d.js"}))

    precompiled = Site::Assets::Precompiled.new(@root)

    assert_nil precompiled["missing.js"]
  end

  def test_read_returns_contents_of_precompiled_file
    write_manifest(%({"app.js": "app-8f3a2b1c9d.js"}))
    FileUtils.mkdir_p(File.join(@root, "assets"))
    File.write(File.join(@root, "assets", "app-8f3a2b1c9d.js"), "console.log(1)\n")

    precompiled = Site::Assets::Precompiled.new(@root)

    assert_equal "console.log(1)\n", precompiled.read("app.js")
  end

  def test_read_returns_nil_when_file_missing_on_disk
    write_manifest(%({"app.js": "app-8f3a2b1c9d.js"}))

    precompiled = Site::Assets::Precompiled.new(@root)

    assert_nil precompiled.read("app.js")
  end

  def test_missing_manifest_is_handled_gracefully
    precompiled = Site::Assets::Precompiled.new(@root)

    assert_nil precompiled["app.js"]
    assert_nil precompiled.read("app.js")
  end

  def test_manifest_must_be_valid_json
    # YAML-style content is NOT valid JSON: loading must fail loudly so a
    # wrongly-formatted manifest cannot silently produce garbage lookups.
    write_manifest("app.js: app-8f3a2b1c9d.js\n")

    precompiled = Site::Assets::Precompiled.new(@root)

    assert_raises(JSON::ParserError) { precompiled["app.js"] }
  end
end

require_relative "test_helper"

# Regression tests for Site::Importers::Files.
#
# Bug fixed: infer_type_from_file_name returned nil when the file name did
# not match the "name.type.exts" pattern, so data[:type] could be nil.
# Behavior is now defined: files without an explicit type segment default
# to DEFAULT_TYPE ("page"); front-matter :type always wins.
class ImportersFilesTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir("poa-import-")
    @importer = Site::Importers::Files.new
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def write_file(name, contents)
    path = File.join(@dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
    path
  end

  def test_type_is_inferred_from_file_name_segment
    write_file("2026-03-06-enso.artykul.md", "---\ntitle: Ensō\n---\nTreść.")

    data = @importer.call(@dir).first

    assert_equal "artykul", data[:type]
  end

  def test_file_without_type_segment_gets_default_type
    write_file("notatka.md", "Zwykły plik bez front matter.")

    data = @importer.call(@dir).first

    assert_equal Site::Importers::Files::DEFAULT_TYPE, data[:type]
    assert_equal "page", data[:type]
  end

  def test_front_matter_type_wins_over_file_name
    write_file("2026-03-06-enso.artykul.md", "---\ntitle: Ensō\ntype: wpis\n---\nTreść.")

    data = @importer.call(@dir).first

    assert_equal "wpis", data[:type]
  end

  def test_parsed_data_contains_path_and_body
    write_file("podstrony/o-dojo.md", "---\ntitle: O dojo\n---\nCiało strony.")

    data = @importer.call(@dir).first

    assert_equal "podstrony/o-dojo.md", data[:path]
    assert_equal "Ciało strony.\n", data[:body]
    assert_equal "O dojo", data[:title]
  end

  def test_default_type_constant_is_documented
    assert_equal "page", Site::Importers::Files::DEFAULT_TYPE
  end
end

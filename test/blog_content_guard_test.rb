require_relative "test_helper"

# Process wording (translator notes, research logs, drafting leftovers) must
# never reach published blog text. Mechanical guard; tone stays in review.
class BlogContentGuardTest < Minitest::Test
  FORBIDDEN = [
    /przekład z ang/i,
    /wstępn\w* notat/i,
    /preliminary notes/i,
    /\bResearch (?:nie|had|did)\b/,
    /research had no access/i,
    /cited-as/i
  ].freeze

  def test_blog_templates_carry_no_process_leaks
    Dir.glob(site_root.join("templates/blog/*.erb").to_s).each do |path|
      text = File.read(path)
      FORBIDDEN.each do |re|
        refute_match(re, text, "#{File.basename(path)} leaks process wording: #{re.source}")
      end
    end
  end
end

# frozen_string_literal: true

module ApplicationHelper
  # Simple markdown-like formatting for messages
  #
  # NOTE: We intentionally keep this lightweight (no full Markdown gem), but we
  # do support GitHub-style tables so financial reports render nicely.
  def simple_format_with_markdown(text)
    return "" if text.blank?

    # Escape HTML first so user content can't inject tags.
    html = h(text.to_s)

    # Extract fenced code blocks first so table parsing doesn't touch them.
    code_blocks = {}
    code_idx = 0
    html.gsub!(/```(\w*)\n(.*?)```/m) do
      lang = Regexp.last_match(1)
      code = Regexp.last_match(2)
      lang_class = lang.present? ? "language-#{lang}" : ""
      token = "@@CODEBLOCK_#{code_idx}@@"
      code_blocks[token] = "<pre class=\"bg-gray-900 rounded-lg p-3 my-2 overflow-x-auto\"><code class=\"#{lang_class} text-sm\">#{code}</code></pre>"
      code_idx += 1
      token
    end

    # Convert markdown tables
    html = render_markdown_tables(html)

    # Inline code
    html.gsub!(/`([^`]+)`/, '<code class="bg-gray-700 px-1.5 py-0.5 rounded text-sm text-purple-300">\1</code>')

    # Bold
    html.gsub!(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')

    # Italic
    html.gsub!(/\*([^*]+)\*/, '<em>\1</em>')

    # Headers
    html.gsub!(/^### (.+)$/, '<h4 class="text-md font-semibold text-gray-200 mt-3 mb-1">\1</h4>')
    html.gsub!(/^## (.+)$/, '<h3 class="text-lg font-semibold text-gray-100 mt-4 mb-2">\1</h3>')
    html.gsub!(/^# (.+)$/, '<h2 class="text-xl font-bold text-gray-100 mt-4 mb-2">\1</h2>')

    # Lists (simple)
    html.gsub!(/^- (.+)$/, '<li class="ml-4">\1</li>')
    html.gsub!(/^(\d+)\. (.+)$/, '<li class="ml-4">\2</li>')

    # Links (only allow http(s))
    html.gsub!(/\[([^\]]+)\]\(([^)]+)\)/) do
      label = Regexp.last_match(1)
      href = Regexp.last_match(2).to_s.strip
      if href.start_with?("http://", "https://")
        '<a href="' + href + '" class="text-purple-400 hover:underline" target="_blank" rel="noopener noreferrer">' + label + "</a>"
      else
        label
      end
    end

    # Restore code blocks
    code_blocks.each do |token, block_html|
      html.gsub!(token, block_html)
    end

    # Line breaks to paragraphs.
    # Disable built-in sanitize because we already escaped user input and only
    # insert known-safe tags.
    simple_format(html, {}, sanitize: false).html_safe
  end

  def render_markdown_tables(html)
    lines = html.to_s.split("\n", -1)
    out = []
    i = 0

    while i < lines.length
      line = lines[i]
      nxt = lines[i + 1]

      if line&.include?("|") && nxt && table_separator_line?(nxt)
        header = parse_table_row(line)
        sep = parse_table_separator(nxt)

        rows = []
        j = i + 2
        while j < lines.length
          break unless lines[j].include?("|")
          break if lines[j].strip.blank?

          rows << parse_table_row(lines[j])
          j += 1
        end

        out << build_table_html(header, rows, sep)
        i = j
        next
      end

      out << line
      i += 1
    end

    out.join("\n")
  end

  def table_separator_line?(line)
    l = line.to_s.strip
    return false unless l.include?("-")
    # Allow optional leading/trailing pipes; dashes/colons/spaces between pipes.
    l.match?(/\A\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)+\|?\z/)
  end

  def parse_table_row(line)
    parts = line.to_s.strip.split("|")
    parts.shift if parts.first&.strip == ""
    parts.pop if parts.last&.strip == ""
    parts.map { |p| p.to_s.strip }
  end

  def parse_table_separator(line)
    cells = parse_table_row(line)
    cells.map do |c|
      s = c.to_s.strip
      if s.start_with?(":") && s.end_with?(":")
        :center
      elsif s.end_with?(":")
        :right
      else
        :left
      end
    end
  end

  def build_table_html(header_cells, rows, alignments)
    cols = [header_cells.size, rows.map(&:size).max || 0].max

    alignments = (alignments || []).dup
    alignments.fill(:left, alignments.length...cols)

    ths = (0...cols).map do |idx|
      content = header_cells[idx].to_s
      klass = "px-3 py-2 border-b border-gray-700 font-semibold text-gray-200 whitespace-nowrap #{table_align_class(alignments[idx])}"
      "<th class=\"#{klass}\">#{content}</th>"
    end.join

    body_rows = rows.map do |r|
      tds = (0...cols).map do |idx|
        content = r[idx].to_s
        klass = "px-3 py-2 border-b border-gray-800 text-gray-100 align-top #{table_align_class(alignments[idx])}"
        "<td class=\"#{klass}\">#{content}</td>"
      end.join
      "<tr class=\"odd:bg-gray-900/20\">#{tds}</tr>"
    end.join

    <<~HTML.strip
      <div class="my-3 overflow-x-auto">
        <table class="min-w-full text-sm border-collapse">
          <thead class="bg-gray-800/60"><tr>#{ths}</tr></thead>
          <tbody>#{body_rows}</tbody>
        </table>
      </div>
    HTML
  end

  def table_align_class(align)
    case align
    when :right then "text-right"
    when :center then "text-center"
    else "text-left"
    end
  end

  # Time ago in words with short format
  def short_time_ago_in_words(time)
    distance = (Time.current - time).to_i

    case distance
    when 0..59
      "#{distance}s"
    when 60..3599
      "#{distance / 60}m"
    when 3600..86_399
      "#{distance / 3600}h"
    when 86_400..604_799
      "#{distance / 86_400}d"
    else
      time.strftime("%b %d")
    end
  end

  # Alias for markdown rendering
  def markdown(text)
    simple_format_with_markdown(text)
  end
end

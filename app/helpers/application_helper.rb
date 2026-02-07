# frozen_string_literal: true

module ApplicationHelper
  # Simple markdown-like formatting for messages
  def simple_format_with_markdown(text)
    return "" if text.blank?

    # Escape HTML first
    html = h(text)

    # Code blocks with syntax highlighting
    html.gsub!(/```(\w*)\n(.*?)```/m) do
      lang = Regexp.last_match(1)
      code = Regexp.last_match(2)
      lang_class = lang.present? ? "language-#{lang}" : ""
      "<pre class=\"bg-gray-900 rounded-lg p-3 my-2 overflow-x-auto\"><code class=\"#{lang_class} text-sm\">#{code}</code></pre>"
    end

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

    # Lists
    html.gsub!(/^- (.+)$/, '<li class="ml-4">\1</li>')
    html.gsub!(/^(\d+)\. (.+)$/, '<li class="ml-4">\2</li>')

    # Links
    html.gsub!(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2" class="text-purple-400 hover:underline" target="_blank">\1</a>')

    # Line breaks to paragraphs
    simple_format(html).html_safe
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

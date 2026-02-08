# frozen_string_literal: true

# Loads the browser-agent skill instructions from the local pi skill file and
# returns a compact snippet that we can prepend to prompts.
#
# This ensures the Rails app and the pi agent follow the same web-browsing rules:
# use bash + agent-browser, never curl/wget, never paid web-search plugins.
class BrowserAgentInstructions
  DEFAULT_SKILL_PATH = File.expand_path("~/.pi/agent/skills/browser-agent/SKILL.md").freeze
  CACHE_KEY = "browser_agent_instructions/v2".freeze

  class << self
    def text
      Rails.cache.fetch(CACHE_KEY, expires_in: 10.minutes) do
        load_and_compact
      end
    rescue StandardError => e
      Rails.logger.warn("BrowserAgentInstructions: fallback due to #{e.class}: #{e.message}")
      fallback_text
    end

    private

    def skill_path
      ENV["PI_BROWSER_AGENT_SKILL_PATH"].presence || DEFAULT_SKILL_PATH
    end

    def load_and_compact
      path = skill_path
      raw = File.read(path)

      # Strip YAML frontmatter if present
      raw = raw.sub(/\A---\s*\n.*?\n---\s*\n/m, "")

      # Extract only the most relevant parts to keep token usage low.
      # We keep: title + Rule + Quick start recipes (up to Notes)
      extracted = if raw.include?("## Rule")
        raw.split("## Rule", 2).last
      else
        raw
      end

      extracted = "## Rule#{extracted}" if raw.include?("## Rule")

      extracted = extracted.split("## Notes", 2).first if extracted.include?("## Notes")

      compact = extracted.strip

      # Wrap it in a small header to make intent explicit.
      <<~TEXT.strip
        ## Web search (exa-search)
        - Prefer exa-search for basic web search and summaries when you do not need to navigate pages.
        - Use browser-agent only for interactive navigation, logins, or form submissions.

        ## Web browsing (browser-agent)
        #{compact}

        ## Optional: reuse an existing Chrome tab (logged-in)
        - If you need the user's already-logged-in session, ask them to start `bin/pi-browser-relay`, load the unpacked extension from `tools/pi-browser-relay/extension`, click the toolbar icon on the tab (badge ON), then run: `agent-browser connect http://127.0.0.1:18792`.
      TEXT
    end

    def fallback_text
      <<~TEXT.strip
        ## Web search (exa-search)
        - Prefer exa-search for basic web search and summaries when you do not need to navigate pages.
        - Use browser-agent only for interactive navigation, logins, or form submissions.

        ## Web browsing (browser-agent)
        When you need information from the internet:
        - Always use the bash tool to run agent-browser.
        - Never use curl/wget.

        Recipes:
        - Search: agent-browser open "https://duckduckgo.com/?q=<query>"
        - Inspect: agent-browser snapshot
        - Extract: agent-browser get title / get url / get text @ref
      TEXT
    end
  end
end

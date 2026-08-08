#!/usr/bin/env python3
"""Replace the four case/when SEO method bodies in context.rb with
data-driven lookups against Site::View::SeoData (1:1 behavior)."""
import re

PATH = "lib/site/view/context.rb"
src = open(PATH, encoding="utf-8").read()

NEW_BODIES = {
    "default_title_for_path": """      def default_title_for_path(path)
        Site::View::SeoData.lookup(
          Site::View::SeoData::DEFAULT_TITLES,
          Site::View::SeoData::DEFAULT_TITLES_PATTERNS,
          site_name,
          path
        )
      end""",
    "default_description_for_path": """      def default_description_for_path(path)
        Site::View::SeoData.lookup(
          Site::View::SeoData::DEFAULT_DESCRIPTIONS,
          Site::View::SeoData::DEFAULT_DESCRIPTIONS_PATTERNS,
          page_title,
          path
        )
      end""",
    "default_keywords_for_path": """      def default_keywords_for_path(path)
        Site::View::SeoData.lookup(
          Site::View::SeoData::DEFAULT_KEYWORDS,
          Site::View::SeoData::DEFAULT_KEYWORDS_PATTERNS,
          Site::View::SeoData::DEFAULT_KEYWORDS_FALLBACK,
          path
        )
      end""",
    "article_schema_for_current_path": """      def article_schema_for_current_path
        entry = Site::View::SeoData::ARTICLE_SCHEMA_DATA[current_path.to_s]
        return "" unless entry

        article_schema(
          name: entry[:name],
          description: page_description,
          image: page_social_image_url,
          lang: entry.fetch(:lang, "pl"),
          date_published: entry[:date_published],
          date_modified: entry.fetch(:date_modified, entry[:date_published])
        )
      end""",
}

for method, new_body in NEW_BODIES.items():
    # Method start: 6-space indent (module > class), def name (with or without args).
    m = re.search(rf"\n      def {method}(?:\([^)]*\))?\n", src)
    assert m, f"method {method} not found"
    start = m.start() + 1  # keep the leading newline

    # Method end: first line with exactly 6-space indentation "end" after start.
    end_m = re.search(r"\n      end\n", src[start:])
    assert end_m, f"end of {method} not found"
    end = start + end_m.end()  # consume the original "      end\n" too

    src = src[:start] + new_body + src[end:]

# Add the require next to the other requires.
if 'require "site/view/seo_data"' not in src:
    src = src.replace(
        'require "site/import"\n',
        'require "site/import"\nrequire "site/view/seo_data"\n',
        1,
    )

open(PATH, "w", encoding="utf-8").write(src)
print("context.rb rewritten")

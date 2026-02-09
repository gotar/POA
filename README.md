# Polska Organizacja Aikido

Static site generator built with [dry-system][dry-system] and [dry-view][dry-view].

[dry-system]: http://dry-rb.org/gems/dry-system
[dry-view]: http://dry-rb.org/gems/dry-view

## Getting started

Run `./bin/setup` to set up the application.

Review `.env` and adjust the settings as required. You can set:
- `SITE_NAME` - Site name (default: "Polska Organizacja Aikido")
- `SITE_AUTHOR` - Site author (default: "POA")
- `SITE_URL` - Site URL (default: "https://aikido-polska.eu")

## Building the site

Run `./bin/build` to build the site. This will empty the `build/` directory and then repopulate it with a new copy of the site's files.

### Development with auto-rebuild

Run `bundle exec guard` to start automatic rebuilding when files change. The guard configuration is in `Guardfile`.

## Deploying the site

Run `./bin/deploy` to deploy the site. This will:
1. Build the site
2. Commit the build changes
3. Push the `build/` directory to the `gh-pages` branch

The site will be live at https://aikido-polska.eu/ within a few minutes.

## Structure

### System

The application is managed by [dry-system][dry-system] (which is set up in the `system/` dir). The system manages the classes defined in `lib/site/` and populates a container for returning instances of these classes, ready to use. It also provides an `Import` mixin for declaring dependencies to be injected into these instances, which makes object composition easy and allows for application logic to be broken down into smaller, more focused units.

In this application, the system provides two special components:

- `settings`, which provides the settings defined in `system/providers/settings.rb`, loaded from either `.env` or the `ENV`
- `assets`, which provides asset path helpers for the views

### Static Content

This application generates static HTML pages without a database. All content is managed through:

- **Templates** in `templates/` - ERB templates for pages and layouts
- **Views** in `lib/site/views/` - View controllers that prepare data for templates
- **Assets** in `assets/` - Images, CSS, and favicon files

### Build process

The build process is managed by `lib/site/generate.rb`, which:

1. Copies static assets (images, CSS, favicons) to the `build/` directory
2. Renders views for each page using dry-view
3. Exports rendered HTML files to the `build/` directory

Each page is rendered with a context (see `lib/site/view/context.rb`) that provides:
- Site settings (name, author, URL)
- Page-specific SEO meta tags (title, description, keywords)
- Asset helpers with cache-busting
- Canonical URLs and Open Graph tags

### Views

Views are rendered using [dry-view][dry-view]. dry-view allows us to define **view controllers** that work with injected dependencies (using our system's `Import` module) from across the application to prepare data and expose it to the view template.

In this application, views are defined in `lib/site/views/`, with separate namespaces for:
- Polish pages: `lib/site/views/` (root namespace)
- English pages: `lib/site/views/en/`

Views use a **context** (defined in `lib/site/view/context.rb`) that provides:
- Site settings (name, author, URL)
- Page title management
- SEO meta tags with per-page defaults (description, keywords)
- Canonical URLs and Open Graph tags
- Asset path helpers with automatic cache-busting
- Current path for navigation state

## Adding new pages

To add a new page:

1. **Create a view controller** in `lib/site/views/` (or `lib/site/views/en/` for English):
   ```ruby
   module Site
     module Views
       class NewPage < View::Controller
         configure do |config|
           config.template = "new_page"
         end
       end
     end
   end
   ```

2. **Create a template** in `templates/` (use existing templates as reference):
   ```erb
   <% page_title "New Page Title" %>
   <h1>New Page</h1>
   ```

3. **Add to generate.rb** to render during build:
   ```ruby
   render export_dir, "new-page.html", new_page_view
   ```

4. **Add SEO metadata** (optional) in `lib/site/view/context.rb`:
   - Update `default_description_for_path()` method
   - Update `default_keywords_for_path()` method

## SEO Features

The site includes comprehensive SEO optimization:

- **Per-page meta descriptions** - Unique descriptions for key pages
- **Per-page meta keywords** - Targeted keywords for search engines
- **Canonical URLs** - Prevents duplicate content issues
- **Open Graph tags** - Optimized for social media sharing (Facebook, Twitter, LinkedIn)
- **Cache-busting** - Automatic versioning for CSS and assets

Key pages with custom SEO:
- Polish homepage: Polish-language SEO focused on Gdynia/Trójmiasto
- English homepage: English-language SEO for international audience
- What is Aikido: Detailed description of Aikido principles

## Technology Stack

- **Ruby** - Core language
- **dry-rb ecosystem** - Application architecture
  - [dry-system][dry-system] - Dependency injection and component management
  - [dry-view][dry-view] - View rendering with contexts
- **ERB** - Template engine
- **GitHub Pages** - Hosting (via `gh-pages` branch)

## How the project works (high-level)

- **Rendering entry point:** `lib/site/generate.rb` is the build orchestrator. Every page that should appear in the build must be rendered there.
- **View controllers:** `lib/site/views/**` define controllers that select templates and (optionally) layouts. They are auto-registered by `dry-system` via `system/site/container.rb`.
- **Templates:** `templates/**` hold ERB templates. English templates typically use the `_en` suffix and a `site_en` layout in the view config.
- **SEO context:** `lib/site/view/context.rb` provides titles, descriptions, keywords, canonical URLs, and hreflang alternates per path.
- **Static assets:** copied from `assets/` into `build/` during `./bin/build`. The `assets/sitemap.xml` file is copied as-is.

## Adding a new page (checklist)

1. **Create templates**
   - Polish: `templates/.../page.html.erb`
   - English: `templates/.../page_en.html.erb`

2. **Create view controllers**
   - Polish: `lib/site/views/.../page.rb`
   - English: `lib/site/views/en/.../page.rb` with `config.layout = "site_en"`

3. **Register in the build**
   - Add `render export_dir, "path/to/page.html", view_instance` in `lib/site/generate.rb`.

4. **Update navigation (if needed)**
   - Polish menu: `templates/layouts/_nav.html.erb`
   - English menu: `templates/layouts/_nav_en.html.erb`

5. **Add SEO defaults**
   - `default_title_for_path`, `default_description_for_path`, `default_keywords_for_path` in `lib/site/view/context.rb`.

6. **Add hreflang mapping**
   - Update `LANG_URL_MAP` in `lib/site/view/context.rb` for the new PL/EN URL pair.

7. **Update the sitemap**
   - Add URLs to `assets/sitemap.xml` (copied verbatim into the build).

8. **Build locally**
   - Run `./bin/build` and verify `build/` contains the new HTML files.

## Deploy

- Run `./bin/deploy` to build and publish the `build/` directory to the `gh-pages` branch.
- The script performs: **build → commit build output → push gh-pages**.
- After pushing, the site is available at `https://aikido-polska.eu/` within a few minutes.

## Common SEO features

- **Titles, descriptions, keywords:** defined by path in `lib/site/view/context.rb`.
- **Canonical URLs:** `Context#canonical_url` uses `SITE_URL` + current path.
- **Hreflang alternates:** generated from `LANG_URL_MAP` in `Context#page_hreflang_tags`.
- **Open Graph tags:** provided by the shared layout templates.

## Notes on English pages

- English pages use separate views under `lib/site/views/en/**` and typically point to `templates/..._en.html.erb`.
- Ensure both the PL and EN versions are rendered and mapped for hreflang and sitemap.


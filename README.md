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


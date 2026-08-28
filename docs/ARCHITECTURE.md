# POA Architecture Guide

## Overview

This is a **static site generator** for the Polish Aikido Organization (Polska Organizacja Aikido) website. It's built using the dry-rb ecosystem, specifically **dry-system** and **dry-view**, and generates static HTML files deployed to GitHub Pages.

**Key Point**: There are NO "agents" in the AI/autonomous sense. The term "agent" in dry-rb refers to **dependency injection containers and components** - think of them as organized, injectable Ruby objects.

---

## Technology Stack

| Component | Purpose |
|-----------|---------|
| **Ruby** | Core language |
| **dry-system** | Dependency injection container & component management |
| **dry-view** | View rendering with contexts |
| **ERB** | Template engine |
| **GitHub Pages** | Static hosting (via `gh-pages` branch) |

---

## System Architecture

### High-Level Flow

```
bin/build (entry point)
    ↓
system/boot.rb (container initialization)
    ↓
Site::Container.build
    ↓
lib/site/build.rb (orchestration)
    ↓
    ├─→ lib/site/prepare.rb (preparation)
    └─→ lib/site/generate.rb (generation)
        ↓
        ├─→ Copy static assets (images, CSS, favicons)
        └─→ Render views (40+ pages)
            ↓
            ├─→ View Controllers (lib/site/views/*.rb)
            ├─→ Templates (templates/*.erb)
            └─→ Context (lib/site/view/context.rb)
                ↓
                Outputs: build/*.html
```

---

## Core Components

### 1. Container System (`system/`)

The **Container** is dry-system's dependency injection mechanism. Think of it as a registry of components that can be auto-injected.

#### `system/site/container.rb`
```ruby
class Container < Dry::System::Container
  configure do |config|
    config.root = Pathname(__dir__).join("../..").realpath
    config.component_dirs.add "lib" do |dir|
      dir.namespaces.add "site", key: nil
    end
    config.provider_dirs = ["system/providers"]
  end
end
```

**What it does**:
- Scans `lib/site/` for Ruby classes
- Auto-registers them as injectable components
- Loads providers from `system/providers/`
- Provides `Site::Container["component_name"]` for dependency resolution

#### Providers (`system/providers/`)

Providers are special components registered manually:

**`settings.rb`** - Configuration from `.env` or `ENV`:
- `SITE_NAME` - Site name (default: "Polska Organizacja Aikido")
- `SITE_AUTHOR` - Author (default: "POA")
- `SITE_URL` - Base URL (default: "https://aikido-polska.eu")
- `IMPORT_DIR` / `EXPORT_DIR` - Input/output directories
- `ASSETS_PRECOMPILED` / `ASSETS_SERVER_URL` - Asset handling

**`assets.rb`** - Asset path helpers:
- Returns precompiled or served asset paths
- Used for cache-busting and CDN integration

### 2. Import Mixin (`system/site/import.rb`)

**Purpose**: Dependency injection DSL for classes

```ruby
class Generate
  include Import[
    "settings",
    export: "exporters.files",
    home_view: "views.home"
  ]
end
```

This injects:
- `settings` → `Site::Container["settings"]`
- `export` → `Site::Container["exporters.files"]`
- `home_view` → `Site::Container["views.home"]`

---

## Build Process

### Entry Point: `bin/build`

```ruby
#!/usr/bin/env ruby
require_relative "../system/boot"

# Clean build directory
FileUtils.rm_rf(export_dir)

# Trigger build
Site::Container.build
```

**Options**:
- `--clean` (default: true) - Wipe `build/` before generating
- `--no-clean` - Incremental build

### Step 1: Build Orchestration (`lib/site/build.rb`)

```ruby
class Build
  include Import["prepare", "generate"]

  def call(root)
    yield prepare.(root)    # Step 1: Prepare
    yield generate.(root)   # Step 2: Generate
    Success(root)
  end
end
```

Uses **dry-monads** for railway-oriented programming (Success/Failure flow).

### Step 2: Prepare (`lib/site/prepare.rb`)

Not shown in codebase, but likely handles:
- Directory structure validation
- Asset preprocessing
- Cache cleanup

### Step 3: Generate (`lib/site/generate.rb`)

**This is the heart of the system.** It:

1. **Copies static assets**:
   ```ruby
   FileUtils.cp_r "assets/images", "build/assets/images"
   FileUtils.cp "assets/style.css", "build/assets/style.css"
   FileUtils.cp_r "assets/favicons/.", "build/"
   ```

2. **Renders 40+ pages**:
   ```ruby
   render export_dir, "index.html", home_view
   render export_dir, "en/index.html", home_en_view
   render export_dir, "kontakt.html", contact_view
   # ... 37+ more pages
   ```

**`render()` method**:
```ruby
def render(export_dir, path, view, **input)
  base_context = Site::Container["view.context"]
  processed_path = path.sub(%r{/index.html$}, "")
  context = base_context.new(current_path: processed_path)

  export.(export_dir, path, view.(context: context, **input))
end
```

**Flow**:
1. Create context with current path
2. Call view controller with context
3. Export rendered HTML to file

---

## View System

### Architecture

```
View Controller (Ruby)
    ↓
Template (ERB)
    ↓
Context (shared data)
    ↓
Rendered HTML
```

### View Controllers (`lib/site/views/*.rb`)

**Base Class**: `Site::View::Controller` (wraps `Dry::View`)

**Example** - `lib/site/views/home.rb`:
```ruby
module Site
  module Views
    class Home < View::Controller
      configure do |config|
        config.template = "home"  # Maps to templates/home.html.erb
      end
    end
  end
end
```

**What it does**:
- Declares which template to use
- Can define `expose` methods to pass data to templates
- Inherits layout configuration (`site.html.erb` by default)

**Namespacing**:
- Polish pages: `Site::Views::*` → `lib/site/views/`
- English pages: `Site::Views::En::*` → `lib/site/views/en/`

### Templates (`templates/*.html.erb`)

**Standard ERB** with access to:
- Context methods (`page_title`, `asset_path`, etc.)
- Exposed data from view controllers
- Layout wrapping

**Example**:
```erb
<% page_title "Home" %>

<h1>Welcome to <%= site_name %></h1>
<img src="<%= asset_path_with_version('/assets/images/logo.png') %>">
```

### Context (`lib/site/view/context.rb`)

**Purpose**: Shared data/helpers for ALL templates

**Key Methods**:

| Method | Purpose | Example |
|--------|---------|---------|
| `page_title(title)` | Set page title | `<% page_title "Contact" %>` |
| `page_title` (no args) | Get full title | `<title><%= page_title %></title>` |
| `page_description` | SEO meta description | Per-page defaults |
| `page_keywords` | SEO meta keywords | Per-page defaults |
| `canonical_url` | Canonical link tag | Prevents duplicate content |
| `asset_path(path)` | Asset URL | Supports CDN |
| `asset_path_with_version(path)` | Cache-busted asset | Adds a content digest, e.g. `?v=e562dec06d` |
| `site_name` | Site name from settings | "Polska Organizacja Aikido" |
| `site_author` | Author from settings | "POA" |
| `site_url` | Base URL from settings | "https://aikido-polska.eu" |

**Context Lifecycle**:
1. Container creates base context: `Site::Container["view.context"]`
2. Generate creates instance with `current_path: "kontakt.html"`
3. Context passed to view controller
4. View controller passes to template
5. Template calls context methods

**SEO Features**:
- Per-page meta descriptions (40+ unique descriptions)
- Per-page meta keywords (40+ unique keyword sets)
- Canonical URLs
- Open Graph tags support
- Cache-busting for CSS/assets

---

## Content Structure

### Pages Organization

**Polish Pages** (root level):
- `/` - Home (`views.home`)
- `/kontakt.html` - Contact (`views.contact`)
- `/slowniczek.html` - Glossary (`views.glossary`)
- `/aikido/*.html` - Aikido info pages
- `/biografie/*.html` - Biography pages
- `/wymagania_egzaminacyjne/*.html` - Requirements

**English Pages** (`/en/` prefix):
- `/en/` - Home (`views.en.home`)
- `/en/contact.html` - Contact (`views.en.contact`)
- `/en/glossary.html` - Glossary (`views.en.glossary`)
- `/en/aikido/*.html` - Aikido info pages
- `/en/biographies/*.html` - Biography pages
- `/en/requirements/*.html` - Requirements

**Total**: 40+ pages (20 Polish + 20 English + extras)

### Assets Structure

```
assets/
├── images/           # Photos (biographies, backgrounds, glossary)
├── favicons/         # Favicon files (copied to build root)
├── style.css         # Main stylesheet
├── .nojekyll         # GitHub Pages config (no Jekyll processing)
└── CNAME             # Custom domain config
```

---

## Dependency Injection Pattern

### How Components Work Together

**Without Dependency Injection** (bad):
```ruby
class Generate
  def call
    settings = Site::Container["settings"]
    export = Site::Container["exporters.files"]
    home_view = Site::Container["views.home"]
    # ... manual resolution everywhere
  end
end
```

**With Dependency Injection** (good):
```ruby
class Generate
  include Import[
    "settings",
    export: "exporters.files",
    home_view: "views.home"
  ]

  def call
    # Already available as instance methods!
    settings.site_name
    export.(...)
    home_view.(...)
  end
end
```

**Benefits**:
- **Testability**: Inject mocks in tests
- **Loose coupling**: Components don't know about Container
- **Clarity**: Dependencies declared at class level
- **Auto-registration**: No manual wiring needed

---

## Bin Scripts Reference

The `bin/` directory contains executable scripts for common tasks:

### `bin/setup` - Project Setup

**Purpose**: Initialize project dependencies and configuration

```ruby
#!/usr/bin/env ruby
require "fileutils"

APP_ROOT = File.expand_path("..", __dir__)

Dir.chdir(APP_ROOT) do
  puts "Installing Ruby dependencies..."
  system("bundle check") || system("bundle install")

  unless File.exist?(".env")
    if File.exist?(".env-example")
      FileUtils.cp ".env-example", ".env"
      puts "Created .env from .env-example"
    else
      puts "Note: No .env file found. Create one if needed."
    end
  end

  puts "Setup complete!"
end
```

**What it does**:
1. Checks if gems are installed
2. Runs `bundle install` if needed
3. Creates `.env` from `.env-example` if missing

**When to run**: Once after cloning, or after `Gemfile` changes

---

### `bin/build` - Build Site

**Purpose**: Generate static HTML files in `build/` directory

```ruby
#!/usr/bin/env ruby
require "fileutils"
require "optparse"
require "bundler/setup"
require_relative "../system/boot"

options = {
  clean: true,
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/build [options]"

  opts.on("--[no-]clean", "Clean build directory (default: true)") do |v|
    options[:clean] = v
  end
end.parse!

if options[:clean]
  export_dir = Site::Container.config.root.join(Site::Container[:settings].export_dir)
  FileUtils.rm_rf(export_dir, secure: true)
  FileUtils.mkdir_p(export_dir)
end

Site::Container.build
```

**Usage**:
```bash
./bin/build              # Clean build (wipes build/ first)
./bin/build --no-clean   # Incremental build (faster)
```

**Options**:
- `--clean` (default) - Delete `build/` before generating
- `--no-clean` - Keep existing files, only regenerate

**When to run**: After any code/template/asset changes

**Performance**: ~2 seconds for clean build (40 pages)

---

### `bin/console` - Interactive REPL

**Purpose**: Launch Pry console with container loaded

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require_relative "../system/boot"
require "pry"

Pry.start
```

**Usage**:
```bash
./bin/console
```

**What you can do**:
```ruby
# Access container components
Site::Container["settings"].site_name
# => "Polska Organizacja Aikido"

# Render a view manually
view = Site::Container["views.home"]
context = Site::Container["view.context"].new
result = view.(context: context)

# Explore available components
Site::Container.keys
# => ["settings", "assets", "views.home", "views.contact", ...]

# Test helpers
context = Site::Container["view.context"].new(current_path: "kontakt.html")
context.canonical_url
# => "https://aikido-polska.eu/kontakt.html"
```

**When to use**: Debugging, testing components, exploring container

---

### `bin/watch` - Development Server with Auto-Rebuild

**Purpose**: Start local server + auto-rebuild on file changes

```bash
#!/bin/sh

mkdir -p ./build

# Initial build before starting watch
echo "Building site..."
./bin/build

echo "Starting dev server with live reload..."
foreman start -f Procfile.watch
```

**What it does**:
1. Creates `build/` directory
2. Runs initial build
3. Starts Foreman with 2 processes (defined in `Procfile.watch`)

**Usage**:
```bash
./bin/watch
```

**Starts**:
- **Guard process** (file watcher) - Watches `lib/`, `templates/`, `assets/`, triggers `./bin/build --no-clean` on changes
- **Web server** (Rack) - Serves `build/` on http://localhost:8000

**Procfile.watch**:
```
guard: bundle exec guard --no-notify --no-interactions
web: bundle exec ruby -r rackup -e "Rackup::Server.start(config: 'config.ru', Port: 8000, Host: '0.0.0.0')"
```

**Configuration**:

`Guardfile` (file watcher):
```ruby
guard :shell do
  watch %r{(lib|source|system|templates)/.*} do |match|
    puts "#{match[0]} updated"
    `./bin/build --no-clean`
  end
end
```

`config.ru` (web server):
```ruby
require 'rack'

use Rack::Static, urls: [''], root: 'build', index: 'index.html'

run lambda { |env|
  path = env['PATH_INFO']
  file = File.join('build', path)
  
  # Try with .html extension if no extension
  if !File.exist?(file) && !path.include?('.')
    file = File.join('build', "#{path}.html")
  end
  
  if File.exist?(file) && !File.directory?(file)
    [200, {'Content-Type' => Rack::Mime.mime_type(File.extname(file))}, [File.read(file)]]
  else
    [404, {'Content-Type' => 'text/html'}, ['Not Found']]
  end
}
```

**Features**:
- Auto-rebuild on file save
- Serves static files from `build/`
- Extension-less URLs work (`/kontakt` serves `kontakt.html`)
- Proper MIME types

**When to use**: Active development with frequent changes

---

### `bin/deploy-local` - Deploy to GitHub Pages

**Purpose**: Build the site locally and publish the generated `build/` tree to
the `gh-pages` branch. This is the default deploy path since owner policy
2026-08-23. GitHub Actions workflows are dispatch-only and are not part of the
normal gate.

**What it does**:
1. Builds site in `poa-dev:local` when the image exists.
2. Checks out `origin/gh-pages` into a temporary worktree.
3. Replaces that worktree contents with the freshly generated `build/` output.
4. Commits only when the generated tree changed.
5. Pushes the temporary worktree commit to `gh-pages`.

**Usage after reviewed code reaches `master`**:
```bash
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/test'
bin/deploy-local
curl -fsS https://aikido-polska.eu/ | grep -F 'expected new text'
```

**Do not use `bin/deploy` for publication.** It is an obsolete stub that exits
with an instruction to use `bin/deploy-local`.

---

### `bin/rackup` - Bundler-Generated Wrapper

**Purpose**: Bundler-generated wrapper for `rackup` command

**Usage**: Generally not called directly (used by `bin/watch`)

---

## GitHub Pages Deployment

### Architecture

**Branch Strategy**:
```
master (source code only; build/ is gitignored)
  ↓
local deterministic build in poa-dev:local
  ↓
temporary worktree of origin/gh-pages
  ↓
commit generated static files to gh-pages
  ↓
GitHub Pages (hosting)
  ↓
https://aikido-polska.eu/
```

**Key Files**:
- `assets/CNAME` → Domain configuration (`aikido-polska.eu`)
- `assets/.nojekyll` → Disable Jekyll processing on GitHub Pages
- Both copied to `build/` root during build

### How local deploy works

`bin/deploy-local` does not commit `build/` to `master` and does not use the old
subtree workflow. It treats `build/` as generated output, copies it into a clean
temporary worktree for `gh-pages`, then commits and pushes only that deployment
branch.

**master branch**:
```
/
├── lib/
├── templates/
├── assets/
└── build/           ← generated locally, gitignored
```

**gh-pages branch**:
```
/
├── index.html
├── assets/
└── en/
```

### Deployment Workflow

**Step-by-Step**:

1. **Make changes** to source files (`lib/`, `templates/`, `assets/`)

2. **Build locally in the dev container**:
   ```bash
   sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'
   ```

3. **Test locally in the dev container**:
   ```bash
   sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/test'
   ```

4. **Commit source changes**:
   ```bash
   git add lib/ templates/ assets/ docs/ test/
   git commit -m "✨ feat: add new page"
   ```

5. **After review and merge to `master`, deploy locally**:
   ```bash
   bin/deploy-local
   curl -fsS https://aikido-polska.eu/ | grep -F 'expected new text'
   ```

**Important**: the `build/` directory is generated and gitignored. Verify its
contents after a build; do not commit it to `master`.

### Troubleshooting Deployment

#### Issue: Local deploy cannot update `gh-pages`

**Cause**: the temporary deployment worktree could not fast-forward or push.

**Solution**: inspect `bin/deploy-local` output, fetch `origin/gh-pages`, and
resolve the deployment branch explicitly. Do not delete/recreate `gh-pages` as a
routine fix; that was part of the obsolete subtree workflow.

#### Issue: CNAME File Missing

**Symptom**: Domain stops working, redirects to `username.github.io`

**Cause**: `assets/CNAME` not copied to `build/`

**Fix**:
1. Ensure `assets/CNAME` contains: `aikido-polska.eu`
2. Rebuild in `poa-dev:local`.
3. Check that `build/CNAME` contains the domain.
4. Redeploy with `bin/deploy-local` after the reviewed change reaches `master`.

#### Issue: 404 on Subpages

**Symptom**: Homepage works, but `/kontakt.html` returns 404

**Causes**:
1. File not generated during build
2. File was not copied into the `gh-pages` worktree by local deploy

**Fix**:
```bash
# Check build output after a container build
python3 - <<'PY'
from pathlib import Path
print('\n'.join(str(p) for p in Path('build').glob('*.html')))
PY

# Redeploy after merge
bin/deploy-local
```

#### Issue: Changes Not Appearing Live

**Steps to debug**:

1. **Check local build**:
   ```bash
   sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'
   python3 - <<'PY'
from pathlib import Path
assert 'your change' in Path('build/index.html').read_text()
PY
   ```

2. **Check gh-pages branch**:
   ```bash
   git fetch origin gh-pages
   git log origin/gh-pages -1
   # Should match recent deploy commit
   ```

3. **Check GitHub Pages**:
   - Go to repository → Settings → Pages
   - Verify source: `gh-pages` branch, `/` (root)
   - Check last deployment time

4. **Hard refresh browser**: Ctrl+Shift+R (Chrome/Firefox)

### GitHub Pages Configuration

**Repository Settings** (github.com/gotar/POA/settings/pages):
- **Source**: Deploy from branch
- **Branch**: `gh-pages`
- **Folder**: `/` (root)
- **Custom domain**: `aikido-polska.eu`
- **Enforce HTTPS**: ✅ Enabled

**DNS Configuration** (at domain registrar):
```
Type: CNAME
Name: aikido-polska.eu
Value: gotar.github.io
```

**GitHub verifies domain via `CNAME` file in repository root** (copied from `assets/CNAME`)

---

## Development Workflow

### Initial Setup (One-Time)

```bash
# Clone repository
git clone https://github.com/gotar/POA.git
cd POA

# Build the dev image once or after Gemfile changes
sg docker -c 'docker build -f Dockerfile.dev -t poa-dev:local .'

# Build site
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'

# Run tests
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/test'

# Test locally
cd build
python -m http.server 8000
# Open http://localhost:8000
```

### Daily Development

**Option A: Manual Rebuild**
```bash
# Edit files in lib/, templates/, assets/

# Rebuild
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'

# Test
cd build && python -m http.server 8000
```

**Option B: Auto-Rebuild** (recommended)
```bash
# Start watch mode
./bin/watch

# Edit files → auto-rebuilds → auto-refreshes
# Server at http://localhost:8000
```

### Deployment

```bash
# Commit source changes
git add lib/ templates/ assets/
git commit -m "✨ feat: add new feature"
git push

# Deploy after review and merge
bin/deploy-local
```

---

## Quick Command Reference

| Task | Command |
|------|---------|
| **Setup** | `sg docker -c 'docker build -f Dockerfile.dev -t poa-dev:local .'` |
| **Build (clean)** | `sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'` |
| **Build (incremental)** | `sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build --no-clean'` |
| **Tests** | `sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/test'` |
| **Console (REPL)** | `./bin/console` |
| **Dev server + watch** | `./bin/watch` |
| **Deploy** | `bin/deploy-local` |
| **Local server only** | `cd build && python -m http.server 8000` |
| **Check container** | `./bin/console` → `Site::Container.keys` |

---

## Adding New Pages

### Step-by-Step Guide

**1. Create View Controller**

`lib/site/views/training.rb`:
```ruby
module Site
  module Views
    class Training < View::Controller
      configure do |config|
        config.template = "training"
      end

      # Optional: expose data to template
      expose :training_times do
        ["Monday 18:00", "Wednesday 18:00", "Friday 19:00"]
      end
    end
  end
end
```

**2. Create Template**

`templates/training.html.erb`:
```erb
<% page_title "Training Schedule" %>

<h1>Training Times</h1>
<ul>
  <% training_times.each do |time| %>
    <li><%= time %></li>
  <% end %>
</ul>
```

**3. Add to Generate**

`lib/site/generate.rb`:
```ruby
class Generate
  include Import[
    # ... existing imports
    training_view: "views.training"  # Add this
  ]

  def call(root)
    # ... existing renders
    render export_dir, "treningi.html", training_view  # Add this
  end
end
```

**4. Add SEO (Optional)**

`lib/site/view/context.rb`:
```ruby
def default_description_for_path(path)
  case path
  when "treningi.html"
    "Training schedule for Sesshinkan Dojo Gdynia. Classes every Monday, Wednesday, and Friday."
  # ... existing cases
  end
end

def default_keywords_for_path(path)
  case path
  when "treningi.html"
    "training schedule, Aikido classes, Gdynia dojo, practice times"
  # ... existing cases
  end
end
```

**5. Rebuild and Test**
```bash
./bin/build
open build/treningi.html  # Linux: xdg-open
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `bin/build` | Build script entry point |
| `system/boot.rb` | Container initialization |
| `system/site/container.rb` | Container configuration |
| `system/site/import.rb` | Dependency injection DSL |
| `system/providers/settings.rb` | Settings provider (.env) |
| `system/providers/assets.rb` | Asset helpers provider |
| `lib/site/build.rb` | Build orchestration |
| `lib/site/generate.rb` | Page generation logic |
| `lib/site/view/controller.rb` | Base view controller |
| `lib/site/view/context.rb` | Shared template context |
| `lib/site/views/` | View controllers (Polish) |
| `lib/site/views/en/` | View controllers (English) |
| `templates/` | ERB templates |
| `templates/layouts/site.html.erb` | Main layout (Polish) |
| `templates/layouts/site_en.html.erb` | Main layout (English) |
| `assets/` | Static assets (images, CSS) |
| `build/` | Output directory (gitignored) |
| `.env` | Local configuration |
| `Guardfile` | Auto-rebuild configuration |

---

## Common Patterns

### Pattern 1: Bilingual Pages

**Polish Version**:
- Controller: `lib/site/views/contact.rb`
- Template: `templates/contact.html.erb`
- Layout: `templates/layouts/site.html.erb`
- Output: `build/kontakt.html`

**English Version**:
- Controller: `lib/site/views/en/contact.rb`
- Template: `templates/en/contact.html.erb`
- Layout: `templates/layouts/site_en.html.erb`
- Output: `build/en/contact.html`

### Pattern 2: Nested Pages

**Biography pages** are nested under `/biografie/`:
- Controller: `lib/site/views/biographies/toyoda.rb`
- Template: `templates/biographies/toyoda.html.erb`
- Output: `build/biografie/toyoda.html`

**Generate creates directories automatically**:
```ruby
render export_dir, "biografie/toyoda.html", toyoda_view
# Creates: build/biografie/ directory + toyoda.html
```

### Pattern 3: Asset Management

**Images**:
```erb
<img src="<%= asset_path('/assets/images/toyoda/toyoda.jpg') %>">
```

**CSS with cache-busting**:
```erb
<link rel="stylesheet" href="<%= asset_path_with_version('/assets/style.css') %>">
```

Output: `/assets/style.css?v=e562dec06d`

### Pattern 4: SEO Meta Tags

**In templates** (`templates/layouts/site.html.erb`):
```erb
<title><%= page_title %></title>
<meta name="description" content="<%= page_description %>">
<meta name="keywords" content="<%= page_keywords %>">
<link rel="canonical" href="<%= canonical_url %>">
```

**Per-page customization** (in context.rb):
- 40+ unique descriptions
- 40+ unique keyword sets
- Auto-generated from path

---

## Troubleshooting

### Issue: "Component not found"

**Error**: `Dry::Container::Error - Nothing registered with the key "views.new_page"`

**Cause**: View controller not auto-registered

**Fix**:
1. Ensure file is in `lib/site/views/`
2. Ensure proper module structure:
   ```ruby
   module Site
     module Views
       class NewPage < View::Controller
       end
     end
   end
   ```
3. Restart Ruby process (container caches on boot)

### Issue: "Template not found"

**Error**: `Dry::View::TemplateNotFoundError`

**Cause**: Template path mismatch

**Fix**:
1. Check `config.template = "new_page"` in controller
2. Ensure `templates/new_page.html.erb` exists
3. Match exact filename (case-sensitive)

### Issue: "Method undefined in template"

**Error**: `NoMethodError: undefined method 'foo' for #<Context>`

**Cause**: Helper method not defined in context

**Fix**:
1. Add method to `lib/site/view/context.rb`:
   ```ruby
   def foo
     "bar"
   end
   ```
2. Or expose from view controller:
   ```ruby
   expose :foo do
     "bar"
   end
   ```

### Issue: "Assets not updating"

**Cause**: Browser cache

**Fix**:
1. Use `asset_path_with_version` for cache-busting
2. Hard refresh: Ctrl+Shift+R (Chrome/Firefox)
3. Check `build/assets/` has latest files

---

## Design Decisions

### Why dry-rb?

**Pros**:
- **Dependency injection**: Easy testing, loose coupling
- **Auto-registration**: No manual wiring
- **Functional style**: Railway-oriented programming (monads)
- **Modular**: Use only what you need

**Cons**:
- **Learning curve**: Unfamiliar to most Ruby devs
- **Magic**: Auto-registration can be confusing
- **Documentation**: Sparse for newcomers

**Alternative**: Plain Ruby classes with manual dependency passing (simpler but more boilerplate)

### Why Static Site?

**Pros**:
- **Zero runtime**: No server, no database, no attacks
- **Free hosting**: GitHub Pages
- **Fast**: CDN-served HTML
- **Simple deploy**: Git push

**Cons**:
- **No dynamic content**: Can't handle user input
- **Build step required**: Changes require rebuild
- **Limited functionality**: No search, comments, etc.

**Alternative**: Rails/Sinatra for dynamic content (overkill for this use case)

### Why dry-view?

**Pros**:
- **Context objects**: Shared helpers across templates
- **Dependency injection**: Views can inject services
- **Functional**: Views are functions (input → HTML)

**Cons**:
- **Overhead**: Simpler than ActionView, but still complex
- **Community**: Smaller than ERB/Haml alone

**Alternative**: Plain ERB with helper modules (simpler, less features)

---

## Performance Notes

**Build time**: ~2 seconds for 40 pages (cold build)

**Optimizations**:
- **Incremental builds**: `--no-clean` skips directory wipe
- **Asset copying**: Direct filesystem copy (fast)
- **No preprocessing**: CSS/images copied as-is (no SASS/optimization)

**Bottlenecks**:
- Template rendering (40+ views * ERB compilation)
- File I/O (100+ image files copied)

**Not optimized** (acceptable for 40 pages):
- No parallel rendering
- No caching between builds
- No partial template updates

---

## Testing Notes

The project has a Minitest suite, run through `bin/test` inside `poa-dev:local`.
It covers assets, context helpers, generator smoke behavior, SEO snapshots,
blog JSON-LD schema coverage, and deterministic builds.

```bash
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/test'
```

The SEO snapshot fixture is `test/fixtures/seo_snapshot.json`. After a deliberate
SEO data or page-set change, regenerate it with:

```bash
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ruby test/scripts/extract_seo.rb'
```

---

## Future Improvements

### Short-term
- [x] Add tests (view rendering, context methods, generator, SEO snapshot, determinism)
- [ ] Extract hardcoded SEO to YAML files
- [ ] Add development server (WEBrick + live reload)
- [ ] Optimize asset pipeline (SASS, image compression)

### Medium-term
- [ ] Content management via Markdown + frontmatter
- [ ] Multi-language routing (extract Polish/English patterns)
- [x] Sitemap generation (build-time, from rendered pages — see `lib/site/sitemap.rb`)
- [ ] RSS feed generation
- [ ] Search functionality (static JSON index + JS)

### Long-term
- [ ] Consider headless CMS (Contentful, Strapi)
- [ ] Dynamic features (contact form via serverless)
- [ ] A/B testing for SEO
- [ ] Performance monitoring (Core Web Vitals)

---

## Glossary

| Term | Meaning |
|------|---------|
| **Container** | Dependency injection registry (dry-system) |
| **Provider** | Manually registered component with lifecycle |
| **Import** | Dependency injection DSL |
| **View Controller** | Ruby class that prepares data for template |
| **Template** | ERB file with HTML markup |
| **Context** | Shared data/helpers for templates |
| **Expose** | Make data available to template from controller |
| **Layout** | Wrapper template (header/footer) |
| **Monads** | Functional programming pattern (Success/Failure) |
| **Railway-oriented** | Chaining operations that can fail |

---

## Summary

**This is NOT an agent-based AI system.** It's a **static site generator** using:

1. **dry-system** for dependency injection (auto-registration, container)
2. **dry-view** for view rendering (controllers + contexts + templates)
3. **ERB** for HTML templates
4. **GitHub Pages** for hosting

**Key flow**: `bin/build` → Container → Build → Generate → 40+ HTML files → `build/`

**To understand the system**:
1. Start with `bin/build` (entry point)
2. Follow to `lib/site/build.rb` (orchestration)
3. Read `lib/site/generate.rb` (generation logic)
4. Explore view controllers (`lib/site/views/`)
5. Check templates (`templates/`)
6. Understand context (`lib/site/view/context.rb`)

**The "magic"** is in dry-system's auto-registration - Ruby classes in `lib/site/` become injectable components automatically.

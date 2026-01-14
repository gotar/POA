# POA Website Development - Session Knowledge Base

**Last Updated:** January 14, 2026  
**Project:** Polska Organizacja Aikido (POA) Website  
**Repository:** https://github.com/gotar/POA  
**Live Site:** https://aikido-polska.eu/

---

## Project Overview

### Tech Stack
- **Static Site Generator:** Ruby-based using dry-rb ecosystem (dry-system, dry-view, dry-types)
- **Template Engine:** ERB (migrated from Slim)
- **Build System:** Custom Ruby build script (`bin/build`)
- **Deployment:** GitHub Pages via `gh-pages` branch
- **CSS:** Custom CSS (no framework)
- **Server:** Simple Python HTTP server for local dev (port 8000)

### Directory Structure
```
POA/
├── assets/
│   ├── images/           # Images and logos
│   ├── favicons/         # Favicon files
│   ├── style.css         # Main stylesheet
│   ├── CNAME             # Domain: aikido-polska.eu
│   └── .nojekyll         # Disable Jekyll on GitHub Pages
├── templates/
│   ├── layouts/
│   │   ├── site.html.erb       # Polish layout
│   │   ├── site_en.html.erb    # English layout
│   │   ├── _nav.html.erb       # Polish navigation
│   │   └── _nav_en.html.erb    # English navigation
│   ├── *.html.erb              # Polish page templates
│   └── *_en.html.erb           # English page templates
├── lib/site/
│   ├── views/
│   │   ├── *.rb                # Polish view classes
│   │   └── en/*.rb             # English view classes
│   ├── generate.rb             # Build orchestration
│   └── view/controller.rb      # Base view controller
├── build/                      # Generated static site (committed)
│   ├── index.html              # Polish pages
│   └── en/                     # English pages
├── bin/
│   ├── build                   # Build script
│   └── deploy                  # Deploy to gh-pages script
└── docs/
    └── instagram_strategy.md   # Instagram launch guide
```

---

## Major Work Completed (January 2026)

### 1. Template Migration: Slim → ERB ✅
**Date:** January 12-14, 2026  
**Why:** Simplification, better compatibility, easier for contributors

**What was done:**
- Converted all 21+ templates from `.slim` to `.html.erb`
- Updated `Gemfile`: removed `slim`, added `erbse`
- Removed `require "slim"` from `lib/site/view/controller.rb`
- Original `.slim` files kept but unused

**Build Status:** All 21 pages building successfully

---

### 2. English Version Implementation ✅
**Date:** January 14, 2026

#### Architecture
- **URL Structure:** `/en/` prefix for all English pages
- **Dual Layouts:** `site.html.erb` (Polish, lang="pl-PL") vs `site_en.html.erb` (English, lang="en")
- **Dual Navigation:** `_nav.html.erb` vs `_nav_en.html.erb`
- **View Organization:** English views in `lib/site/views/en/` subdirectory

#### Pages Translated (3 Core Pages)
1. **Home:** `/en/index.html`
2. **Contact:** `/en/contact.html`
3. **What is Aikido:** `/en/aikido/what_is.html` (NOT YET REGISTERED IN BUILD - template exists but no view/build entry)

#### Language Switcher
- Red bordered button in navigation
- Polish pages: "EN" button → `/en/`
- English pages: "PL" button → `/`
- CSS class: `.lang-switcher`

#### How to Add New English Pages
1. Create template: `templates/page_name_en.html.erb`
2. Create view: `lib/site/views/en/page_name.rb`
   ```ruby
   require "site/view/controller"
   require "site/import"

   module Site
     module Views
       module En
         class PageName < View::Controller
           configure do |config|
             config.template = "page_name_en"
             config.layout = "site_en"
           end
         end
       end
     end
   end
   ```
3. Register in `lib/site/generate.rb`:
   ```ruby
   # In Import[] block:
   page_name_en_view: "views.en.page_name",
   
   # In call() method:
   render export_dir, "en/page_name.html", page_name_en_view
   ```
4. Build and deploy

---

### 3. Content Expansions ✅

#### A. Czym jest Aikido? (What is Aikido)
**Additions:**
- **Four Fundamental Principles** (Toyoda lineage) - TRANSLATED TO POLISH:
  1. Utrzymuj jeden punkt (Seika no Itten - 臍下一点)
  2. Rozluźnij się całkowicie (Kanzen ni Rirakkusu - 完全にリラックス)
  3. Utrzymuj ciężar na dole (Omosa o Shitagawa ni Tamotsu - 重みを下側に保つ)
  4. Rozszerzaj Ki (Ki o Dashite - 気を出して)
- Each principle: detailed explanation + practical application
- Expanded: Do (道), Aiki (合気), Ki (気) sections
- Masakatsu Agatsu explanation
- Shugyo concept
- Multiple O-Sensei and Toyoda Shihan quotes

#### B. Słowniczek (Glossary)
**Expansion:** ~50 terms → 200+ terms

**Categories:**
- Podstawowe terminy Aikido
- Osoby na treningu (Sensei, Sempai, Kohai, Uke, Nage, etc.)
- Stopnie i rangi (Kyu system: 7 Kyu to 1 Kyu, Dan system)
- Strój i wyposażenie (Keikogi, Hakama, Obi, Bokken, Jo, Tanto)
- Postawa i ruchy (Kamae, Hanmi, Ma-ai, Tai Sabaki, Irimi, Tenkan)
- Kategorie technik (Katame Waza, Nage Waza, Osae Waza, Ukemi Waza)
- Pozycje wykonywania (Tachi Waza, Suwari Waza, Hanmi Handachi)
- Podstawowe techniki unieruchamiające (Ikkyo through Gokyo)
- Podstawowe techniki rzutowe (Shiho Nage, Irimi Nage, Kote Gaeshi, etc.)
- Rodzaje ataków (Shomen Uchi, Yokomen Uchi, various Tsuki)
- Przewroty i upadki (Ukemi, Zempo Kaiten, Koho Tento)
- Tempo i forma (Omote, Ura, Ki no Nagare, Awase)
- Komendy treningowe (Onegaishimasu, Arigato Gozaimashita, Hajime, Yame)
- Filozofia (Masakatsu Agatsu, Shugyo, Mushin, Zanshin, Kokyu, Hara)

#### C. Nowe Strony (New Pages)

**Aiki Taiso** - `/aikido/aiki_taiso.html`
- 16 basic Aikido exercises with Japanese names, translations, descriptions
- Ukemi Waza section (3 main falls)
- Practice guidelines
- Template: `templates/aikido/aiki_taiso.html.erb`
- View: `lib/site/views/aikido/aiki_taiso.rb`

**Reishiki** - `/aikido/reishiki.html`
- Comprehensive dojo etiquette guide
- Rei (bowing): Zarei and Ritsurei
- Dojo behavior, Keikogi details
- Sensei/Sempai/Kohai relationships
- Training procedures, safety rules
- Template: `templates/aikido/reishiki.html.erb`
- View: `lib/site/views/aikido/reishiki.rb`

**Dla Początkujących** - `/aikido/dla_poczatkujacych.html`
- Complete beginner's guide
- What to bring, what to expect
- Training structure (3 phases)
- Kyu/Dan rank system (7 Kyu system, no colored belts)
- Hakama at 2 Kyu
- **Age requirement: 12-13 years minimum**
- Comprehensive FAQ (8 questions)
- Common beginner mistakes
- Template: `templates/aikido/dla_poczatkujacych.html.erb`
- View: `lib/site/views/aikido/beginners.rb`

---

### 4. Biography Updates ✅

**Oskar Szrajer** (`templates/szrajer.html.erb`):
- Added Wadokan Dojo origins (1999, age 15, Sensei Tomasz Tyszka)
- Added martial arts background paragraph:
  - Multi-discipline exposure through Jacek Ostrowski
  - Ju Jitsu/Ju Jutsu training
  - Self-defense/Combat techniques
  - Training with masters from Poland and abroad
  - Enriching Aikido style with diverse martial arts influences

**Jacek Ostrowski** (`templates/ostrowski.html.erb`):
- Added Wadokan connection with Tomasz Tyszka
- Meeting young Oskar Szrajer at Wadokan

---

### 5. Navigation Restructure ✅

**Old Structure:** Organizacja dropdown with exam requirements buried

**New Structure (5 main items):**
```
├─ Aikido (4 items)
│  ├─ Czym jest Aikido?
│  ├─ Historia
│  ├─ Korzyści z treningu
│  └─ Słowniczek
│
├─ Dla Trenujących (5 items)
│  ├─ Dla Początkujących
│  ├─ Aiki Taiso - Ćwiczenia
│  ├─ Reishiki - Etykieta
│  ├─ Stopnie Kyu
│  └─ Stopnie Dan
│
├─ Linia Przekazu (9 items)
│  ├─ Linia przekazu (overview)
│  └─ 8 biographies
│
├─ Wydarzenia 2026
└─ Kontakt
```

**Rationale:**
- Clear user paths: Curious → Aikido | Students → Dla Trenujących | Heritage → Linia Przekazu
- Exam requirements moved from Organizacja to Dla Trenujących
- Scales well for future content

---

### 6. CSS Additions ✅

**File:** `assets/style.css` (~300 lines added)

**New Components:**
- `.principle-card`, `.principles` grid (Four Principles cards)
- `.exercise-card`, `.exercise-name-jp` (Aiki Taiso)
- `.practice-guidelines`, `.bow-types`, `.bow-card` (Reishiki)
- `.beginner-cards`, `.training-structure`, `.rank-system` (Beginners)
- `.faq-section`, `.faq-item`, `.mistakes-section`, `.mistake-card`
- `.cta-buttons`, `.cta-button` (primary and secondary)
- `.lang-switcher` (language switcher button)

**All responsive:** Mobile breakpoints at max-width: 768px

---

### 7. Deployment System Fixed ✅

#### Issue Encountered
- `gh-pages` branch had diverged from master's build history
- `git subtree push` was failing with non-fast-forward error

#### Solution
1. Deleted remote gh-pages branch: `git push origin :gh-pages`
2. Recreated from current build: `git subtree push --prefix build origin gh-pages`

#### Improved Deploy Script (`bin/deploy`)
**Old:** Just `git subtree push --prefix build origin gh-pages`

**New:**
```bash
#!/bin/sh
set -e

echo "Building site..."
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"
bundle exec ./bin/build

echo "Committing build changes..."
git add build
if git diff --cached --quiet; then
  echo "No changes to deploy"
  exit 0
fi

git commit -m "🚀 deploy: update site build"

echo "Deploying to gh-pages..."
if ! git subtree push --prefix build origin gh-pages; then
  echo "Deployment failed. This usually means gh-pages has diverged."
  echo "You can force update by running:"
  echo "  git push origin :gh-pages"
  echo "  git subtree push --prefix build origin gh-pages"
  exit 1
fi

echo "✅ Deployment successful!"
echo "Site will be live at https://aikido-polska.eu/ in a few minutes"
```

**Features:**
- Automatic build before deploy
- Auto-commits build changes
- Error handling with helpful recovery instructions
- Success confirmation

#### Deployment Status
- **Domain:** https://aikido-polska.eu/ (configured in `assets/CNAME`)
- **Last Deploy:** January 14, 2026
- **Master:** `170d86c`
- **gh-pages:** `8d32105` (synced with master build)

---

### 8. Instagram Strategy Document ✅

**File:** `/docs/instagram_strategy.md` (275 lines)

**Comprehensive Launch Guide:**

#### Account Setup
- Handle suggestions: `@sesshinkan_gdynia` or `@poa_aikido_gdynia`
- Complete bio template with emoji
- Link to aikido-polska.eu

#### Content Strategy
**4 Pillars:**
1. Training & Technique (40%)
2. Dojo Life & Community (30%)
3. Educational Content (20%)
4. Events & Seminars (10%)

#### Hashtag Library
**50+ hashtags organized:**
- Primary (always use): #Aikido, #AikidoGdynia, #SesshinkanDojo, #POA
- Secondary by content type: training, community, lineage, location
- Templates for each post type

#### Posting Schedule
**3-4 posts/week:**
- Monday (post-training): 21:30-22:00
- Wednesday (educational): 18:00-20:00
- Friday (pre-training motivation): 16:00-18:00
- Sunday (weekly recap): 10:00-12:00

#### Caption Formula
1. Hook (1-2 sentences)
2. Value (2-3 sentences educational/inspirational)
3. Call-to-Action
4. Hashtags

**Examples provided in Polish**

#### Photo Guidelines
- Technical specs: 1080x1080px minimum, square or portrait
- Content guidelines: clear technique shots, energy and movement
- What to avoid: blurry, poorly lit, messy backgrounds

#### Growth Tactics
- First month: 100 followers
- 3 months: 300 followers
- Metrics to track weekly/monthly

#### 2-Week Content Bank
8 ready-to-implement posts with captions

---

## Important Project Details

### Domain & Deployment
- **Live URL:** https://aikido-polska.eu/ (NOT aikido-poa.pl)
- **Configured in:** `assets/CNAME`
- **Deployment:** GitHub Pages from `gh-pages` branch
- **Build directory:** Committed to master, then pushed to gh-pages via `git subtree`

### Dojo Information

**Sesshinkan Dojo Gdynia:**
- **Location:** ACS - Akademickie Centrum Sportowe AMW
- **Address:** ul. Komandora Podporucznika Jana Grudzińskiego 1, 81-103 Gdynia
- **Training:** Monday & Friday, 20:00 - 21:30
- **Instructor:** Sensei Oskar Szrajer 5 dan
- **First class:** Free!
- **Minimum age:** 12-13 years (teenagers training with adults)

**Polska Organizacja Aikido (POA):**
- **Headquarters:** ul. Słowackiego 50/22, 47-400 Racibórz
- **KRS:** 0000296914
- **NIP:** 639-19-87-254
- **Dojo-cho:** Sensei Oskar Szrajer 5 dan
- **Phone:** +48 608-019-078
- **Email:** oskarszrajer@gmail.com
- **Facebook:** 
  - POA: https://www.facebook.com/aikidoorganization/
  - Sesshinkan Dojo: https://www.facebook.com/dojogdynia/

### Lineage
**Direct Line:**
- O-Sensei Morihei Ueshiba → Kisshomaru Ueshiba → Moriteru Ueshiba (current Doshu)
- O-Sensei → Fumio Toyoda (1947-2001)
- Toyoda → Edward Germanov (7 dan, Bulgarian Aikido Association)
- Germanov → Jacek Ostrowski (1972-2024, 4 dan) & Oskar Szrajer (5 dan)

**Emphasis:** Toyoda lineage - Four Fundamental Principles

### Aikido Specifics at POA
- **Kyu System:** 7 Kyu to 1 Kyu (NOT 6 Kyu system)
- **Belt System:** White belt only (NO colored belts in Aikido)
- **Hakama:** Permitted from 2 Kyu
- **Philosophy:** Toyoda's Four Principles emphasized
- **Training:** Traditional Japanese approach + practical application

---

## Build & Development Commands

### Local Development
```bash
# Start local server (from build directory)
cd /home/gotar/Programowanie/POA/build
python -m http.server 8000

# Access at: http://localhost:8000
```

### Building
```bash
cd /home/gotar/Programowanie/POA
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"
bundle exec ./bin/build
```

### Deployment
```bash
cd /home/gotar/Programowanie/POA
./bin/deploy
```

**OR manual deployment:**
```bash
# Build
bundle exec ./bin/build

# Commit build changes
git add build
git commit -m "🚀 deploy: update site build"
git push

# Deploy to gh-pages
git subtree push --prefix build origin gh-pages
```

### If gh-pages diverges:
```bash
git push origin :gh-pages
git subtree push --prefix build origin gh-pages
```

---

## Key Design Decisions

1. **Toyoda Lineage Emphasis:** Four Principles front and center (distinguishes from other schools)
2. **No Colored Belts:** Explicitly stated - white belt for all Kyu ranks
3. **7 Kyu System:** Start at 7 Kyu (not 6)
4. **Hakama at 2 Kyu:** Clear guidance on when students can wear hakama
5. **Age 12-13 Minimum:** Teenagers training with adults (no kids classes)
6. **Japanese Terminology:** Throughout with romanization and kanji
7. **Comprehensive Over Minimal:** Detailed, useful content rather than placeholders
8. **Mobile-First CSS:** All components responsive

---

## Git Workflow

### Branch Strategy
- **master:** Source code + build directory
- **gh-pages:** Deployment branch (auto-generated from build/)

### Commit Message Convention
- ✨ `feat:` New features
- 🔧 `fix:` Bug fixes
- 📝 `docs:` Documentation
- 🚀 `deploy:` Deployment commits
- 🌍 `i18n:` Internationalization
- 🎨 `style:` CSS/styling changes

### Recent Commits (Jan 14, 2026)
```
170d86c - 🔧 fix: improve deploy script
1f64c00 - 🌍 feat: add English Contact and What is Aikido pages
6a903aa - 📱 docs: add comprehensive Instagram strategy
24f9a85 - 🌍 feat: add English version foundation with language switcher
e5e31c3 - ✨ feat: expand Oskar Szrajer biography
1d15b70 - ✨ feat: migrate Slim to ERB and expand content
```

---

## Current Status

### Completed ✅
- 21 Polish pages fully functional
- 3 English pages live (Home, Contact, What is Aikido template exists)
- Language switcher working
- Deployment pipeline fixed
- Instagram strategy documented
- All changes deployed to https://aikido-polska.eu/

### Remaining Work (Optional)
- Translate remaining 18 pages to English
- Implement What is Aikido English page (template exists, needs view + build registration)
- Create Instagram account and post content (user task)
- Download photos from Facebook (requires manual auth)

---

## Troubleshooting

### Build Issues
**Problem:** Build fails with container key errors  
**Solution:** Check that views are in correct directory structure and imported in `generate.rb`

**Problem:** Template not found  
**Solution:** Verify template name matches config in view class

### Deployment Issues
**Problem:** `git subtree push` fails with non-fast-forward  
**Solution:** Delete and recreate gh-pages branch
```bash
git push origin :gh-pages
git subtree push --prefix build origin gh-pages
```

### Content Issues
**Problem:** Links in navigation don't match English structure  
**Solution:** Update `_nav_en.html.erb` with correct `/en/` prefixed URLs

---

## Future Enhancements (Not Implemented)

1. **More English Pages:** Translate remaining 18 pages incrementally
2. **Advanced Technique Pages:** Individual pages for Ikkyo, Nikyo, etc. with photos/videos
3. **News/Blog Section:** For seminar reports, articles
4. **Photo Gallery:** Training photos, seminar photos
5. **Member Area:** Login system for students (ambitious)
6. **Search Functionality:** For glossary and techniques
7. **Multi-language Selector:** Add more languages beyond PL/EN

---

## Contact & Ownership

**Project Owner:** Sensei Oskar Szrajer  
**Dojo:** Sesshinkan Dojo Gdynia  
**Organization:** Polska Organizacja Aikido  
**Repository:** https://github.com/gotar/POA  
**Website:** https://aikido-polska.eu/

---

## Notes for Future Development

1. **Adding English Pages:**
   - Follow the pattern: template (`*_en.html.erb`) + view (`en/*.rb`) + registration in `generate.rb`
   - Always use `config.layout = "site_en"` for English views
   - Update `_nav_en.html.erb` when adding new pages

2. **CSS Changes:**
   - All styles in single `assets/style.css` file
   - Follow existing naming conventions (BEM-like)
   - Test mobile responsiveness (breakpoint at 768px)

3. **Content Updates:**
   - Polish content is primary source of truth
   - Keep Japanese terminology consistent with existing usage
   - Maintain Toyoda lineage emphasis

4. **Deployment:**
   - Always use `./bin/deploy` script (handles build + commit + push)
   - If script fails, follow error message instructions
   - GitHub Pages deploys automatically from `gh-pages` branch

---

**Document Version:** 1.0  
**Created:** January 14, 2026  
**Purpose:** Knowledge transfer and project continuity

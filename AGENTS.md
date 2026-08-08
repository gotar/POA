# AGENTS.md

## Project

Polska Organizacja Aikido (POA) website — static site generator (Ruby 3.4 + dry-rb/dry-view + ERB), built to `build/`, hosted on GitHub Pages at **https://aikido-polska.eu/** (branch `gh-pages`).

- Repo: `gotar/POA`, default branch `master`
- Owner: Oskar Szrajer (Sensei, 5 dan, Toyoda → Germanov lineage). Dojo Sesshinkan Gdynia.

## Hard Rules

1. **This repo is POA. NEVER Manarr.** Do not load the `manarr-project` skill, do not touch `/home/deck/Programowanie/Manarr`, do not create cards on the `manarr` board, and do not import Manarr deploy rules (Kamal, registry, SSH host) into this project — POA has no secrets, no Kamal, no Docker registry, no deploy host.
2. **Slack channel binding:** `#programowanie-poa` (channel ID `C0BPP9EP43A`) is hard-assigned to this project (gateway profile route → profile `poa`). Every message in that channel concerns POA and POA only. A message that does not name a project explicitly is still POA when it arrives there.
3. **Kanban-first:** every change (content, code, infra) starts with a card on board `poa`: `hermes kanban --board poa create …`. Trivial read-only work may skip cards.
4. **Workflow:** card → dedicated worktree + feature branch → implementation → verification in the `poa-dev:local` container → independent reviewer GO/NO-GO → merge to `master` → GH Actions auto-deploy → verify live → cleanup + close card. Never edit the main checkout or someone else's worktree.
5. **Load the `poa-project` skill first** — it holds the build commands, environment quirks (Docker-only builds on SteamOS), deploy verification and pitfalls.

## Build (Docker only)

Host Ruby cannot install native gems (SteamOS, no `/usr/include/stdio.h`). Build only inside the container:

```sh
sg docker -c 'docker run --rm -v "$PWD:/app" -w /app poa-dev:local ./bin/build'
```

- Build is fully **deterministic**: cache-buster `asset_path_with_version` = content MD5 (`style.css?v=e562dec06d`), not a timestamp. Identical source → identical hashes.
- `build/` is gitignored; `gh-pages` is generated in CI from a clean checkout. Verify builds by checking generated HTML in `build/`, not `git status`.
- Rebuild the image after Gemfile changes: `sg docker -c 'docker build -f Dockerfile.dev -t poa-dev:local .'`
- Local preview: `python3 -m http.server 8000` from `build/`.
- CI (`gh-pages.yml`) builds on ubuntu-latest with ruby 3.4 — works without the container.

## Deploy

- Push to `master` triggers GH Actions (`gh-pages.yml`): build → deploy `build/` to `gh-pages`.
- CI on PRs: `build-check.yml` (build gate).
- Verify deploys via Actions Runs API (`GET /repos/gotar/POA/actions/runs?head_sha=<SHA>`) + `curl -fsS https://aikido-polska.eu/` (HTTP 200) + presence of the new content.

## Content Facts

- **PL is the source of truth**; EN pages under `/en/` (hreflang via `LANG_URL_MAP`).
- 7-kyu system (not 6), white belts only, hakama from 2 kyu, four fundamental principles of Toyoda.
- New page checklist: templates (PL+EN) → views (PL+EN) → registration in `lib/site/generate.rb` → navigation (`_nav.html.erb`/`_nav_en.html.erb`) → SEO defaults in `lib/site/view/context.rb` → `assets/sitemap.xml` → build → commit.
- CSS: single `assets/style.css`, mobile-first (breakpoint 768px), BEM-like. After CSS changes bump the cache-buster version in URLs (content MD5 handles this automatically).
- Full project knowledge base: `docs/AGENTS.md`, `docs/ARCHITECTURE.md`.

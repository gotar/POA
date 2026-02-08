# TODO - Gotar Bot

A mobile-first web UI for the pi coding agent (Rails 8 + Hotwire + Solid Queue).

## Next

## Completed

- [x] Add a small UI for reviewing / pruning imported pi TUI session transcripts

- [x] Scheduled Jobs run automatically (recurring tick)
- [x] Cron parsing uses Fugit
- [x] Monitoring routes + navigation
- [x] Tailwind production build (tailwindcss-rails)
- [x] Global Personal Knowledge area (`/knowledge`)
- [x] Async QMD heavy search modes via Solid Queue + heavy lock
- [x] Chat memory uses curated living docs only (no QMD recall during chat turns)
- [x] Conversation archiving
- [x] Tool execution visibility in chat (tool calls + streaming output)
- [x] Message queueing when a run is in progress
- [x] Heartbeat: system health check every 30 minutes + stuck recovery
- [x] Monitoring: "Run heartbeat now" + "Run polish now" buttons
- [x] Heartbeat: optional agent heartbeat driven by `HEARTBEAT.md` (silent by default)
- [x] Heartbeat: prefers free model + verifies model works before using
- [x] Heartbeat: UI toggles (agent heartbeat enable/disable, skip when busy, push alerts)
- [x] Heartbeat: enforce `--no-tools` for agent-heartbeat pi subprocess
- [x] Heartbeat history table + Monitoring display
- [x] Global QMD diagnostics banner (missing/unhealthy)
- [x] Persistent pi RPC sessions (PiRpcPool) for background jobs
- [x] Daily living-docs polish (auto-update core files at 3am + backups)
- [x] Staggered overnight jobs (backup moved earlier; QMD update moved after polish)
- [x] Jobs service resource constraints (systemd override) + reduced SolidQueue threads
- [x] Scheduled job prompt template auto-update toast
- [x] Import pi TUI session logs into knowledge vault for QMD indexing
- [x] Knowledge export/backup download from UI
- [x] Knowledge governance UI (stale / untagged / large / archive)
- [x] Shift+Enter to send (Enter inserts newline)
- [x] Ensure buttons show pointer cursor

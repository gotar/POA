# TODO - Gotar Bot

A mobile-first web UI for pi coding agent, built with Rails 8, Hotwire, and Stimulus.

## In Progress

None

## Pending

None

## Completed

- [x] Check mobile version and responsiveness
- [x] Fix project page menu dropdown issues
- [x] Fix JavaScript errors in console
- [x] Check all pages for issues and bugs
- [x] Test PI chat communication end-to-end
- [x] Polish UI and fix any remaining issues
- [x] Verify all features work correctly

- Install Ruby 3.3.9 via rbenv
- Install Rails 8.1.2
- Create Rails project with SQLite, Hotwire, Stimulus
- Solid Queue, Solid Cache, Solid Cable configured
- Create Project model with validations
- Create Todo, Note, Conversation, Message models
- Set up routes (nested project-based structure)
- Create all controllers
- Create PiStreamJob and PiRpcService
- Set up Minitest framework
- Create all model tests (100% coverage)
- Create all controller tests (100% coverage)
- Build mobile-first project views
- Build mobile-first conversation views
- Add Stimulus controllers
- Project named "Gotar Bot"
- Create systemd service files
- Create setup script for production
- All tests passing
- Implement QMD CLI integration
- Add knowledge collections UI
- Build search functionality
- Add auto-indexing for uploaded files
- Create cron jobs configuration UI
- Implement scheduled prompts/templates
- Add background knowledge indexing
- Build job monitoring dashboard
- Add PWA support with service worker
- Implement file/image uploads
- Add export conversations to Markdown
- Add metadata to messages for PI usage info
- Fix PATH issue for job queue
- Add interactive TODO and questions panels
- Implement syntax highlighting with Prism.js
- Fix textarea overflow bars
- Add PI footer info (model, usage, cost) to messages
- Fix text delta handling in PiRpcService

## Mobile Fixes Completed

- Fixed JavaScript error in project_controller.js (undefined targets)
- Fixed mobile tab switcher with icons and horizontal scroll
- Fixed todo delete button visibility on mobile
- Fixed dropdown menu accessibility (escape key, touch support)
- Added "Go to Chat" buttons in mobile panels
- Added mobile TODO add form
- Created passwordless sudo configuration
- Created restart-services script

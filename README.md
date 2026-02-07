# Gotar Bot

A mobile-first web UI for pi coding agent, built with Rails 8, Hotwire, and Stimulus.

## Features

- 🤖 **AI Chat Interface** - Communicate with pi coding agent from your browser
- 📱 **Mobile-First Design** - PWA support, works great on phones
- ⚡ **Real-time Streaming** - See AI responses as they're generated
- 💾 **Persistent Conversations** - All chats saved in SQLite database
- 🔄 **Background Jobs** - Solid Queue for async processing
- 🧠 **Knowledge Base** - QMD integration for RAG (planned)
- ⏰ **Scheduled Tasks** - Cron jobs for automation (planned)

## Tech Stack

- **Rails 8.1** with Ruby 3.3
- **Hotwire** (Turbo + Stimulus)
- **SQLite** for database, cache, and queue
- **Solid Queue** for background jobs
- **pi RPC** for AI communication

## Quick Start

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:prepare

# Start the server (with Solid Queue)
bin/rails server
bin/jobs  # In another terminal

# Or use Foreman
gem install foreman
foreman start -f Procfile.dev
```

Visit http://localhost:3000

## Requirements

- Ruby 3.3+
- Node.js 18+ (for pi)
- pi coding agent installed (`npm install -g @mariozechner/pi-coding-agent`)
- API key for Anthropic or OpenAI

## Development

```bash
# Run tests
bin/rails test

# Run specific test file
bin/rails test test/models/conversation_test.rb

# Run with verbose output
bin/rails test TESTOPTS="--verbose"
```

## Project Structure

```
app/
├── controllers/
│   ├── conversations_controller.rb  # Chat list and management
│   └── messages_controller.rb       # Message creation and streaming
├── jobs/
│   └── pi_stream_job.rb            # Background AI processing
├── models/
│   ├── conversation.rb             # Chat session model
│   └── message.rb                  # Individual messages
├── services/
│   └── pi_rpc_service.rb           # pi subprocess communication
└── views/
    └── conversations/              # Chat UI views
```

## License

MIT

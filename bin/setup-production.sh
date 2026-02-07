#!/bin/bash
# Setup script for Gotar Bot production deployment
# Run this once to configure and start the service

set -e

APP_DIR="/home/gotar/pi-web-ui"
SERVICE_DIR="$APP_DIR/.config/systemd"

echo "🤖 Setting up Gotar Bot..."

cd "$APP_DIR"

# Generate secret key base if not set
if ! grep -q "SECRET_KEY_BASE=CHANGE_ME" "$SERVICE_DIR/gotar-bot-web.service" 2>/dev/null; then
  echo "✓ Secret key already configured"
else
  echo "🔑 Generating SECRET_KEY_BASE..."
  SECRET=$(bundle exec rails secret)
  sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET/" "$SERVICE_DIR/gotar-bot-web.service"
  sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET/" "$SERVICE_DIR/gotar-bot-jobs.service"
fi

# Check for API key
if grep -q "ANTHROPIC_API_KEY=YOUR_KEY_HERE" "$SERVICE_DIR/gotar-bot-web.service" 2>/dev/null; then
  echo "⚠️  Please edit the service files and add your ANTHROPIC_API_KEY"
  echo "   Files: $SERVICE_DIR/gotar-bot-web.service"
  echo "          $SERVICE_DIR/gotar-bot-jobs.service"
  exit 1
fi

# Precompile assets
echo "📦 Precompiling assets..."
RAILS_ENV=production bundle exec rails assets:precompile

# Run database migrations
echo "🗄️  Running database migrations..."
RAILS_ENV=production bundle exec rails db:prepare

# Install systemd services
echo "⚙️  Installing systemd services..."
sudo cp "$SERVICE_DIR/gotar-bot-web.service" /etc/systemd/system/
sudo cp "$SERVICE_DIR/gotar-bot-jobs.service" /etc/systemd/system/
sudo systemctl daemon-reload

# Enable and start services
echo "🚀 Starting services..."
sudo systemctl enable gotar-bot-web gotar-bot-jobs
sudo systemctl start gotar-bot-web gotar-bot-jobs

echo ""
echo "✅ Gotar Bot is running!"
echo ""
echo "📊 Status:"
sudo systemctl status gotar-bot-web --no-pager | head -5
echo ""
echo "🌐 Access at: http://localhost:3090"
echo ""
echo "📝 Useful commands:"
echo "   sudo journalctl -u gotar-bot-web -f    # Follow web logs"
echo "   sudo journalctl -u gotar-bot-jobs -f   # Follow job logs"
echo "   sudo systemctl restart gotar-bot-web   # Restart web"
echo "   sudo systemctl restart gotar-bot-jobs  # Restart jobs"

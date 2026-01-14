#!/bin/bash
# Run this script AFTER you complete SMS verification
# This will help collect your Instagram API credentials

set -e

echo "=================================================="
echo "Instagram MCP Credential Collection Script"
echo "=================================================="
echo ""
echo "PREREQUISITE: You must have completed Facebook Developer registration"
echo "and created a Facebook App with Instagram Graph API enabled."
echo ""
echo "This script will guide you through collecting the required credentials."
echo ""

# Function to prompt for input
prompt_credential() {
    local var_name=$1
    local description=$2
    local current_value=$3
    
    echo ""
    echo "---"
    echo "$description"
    if [ ! -z "$current_value" ] && [ "$current_value" != "your_*" ]; then
        echo "Current value: $current_value"
        read -p "Press Enter to keep current value, or enter new value: " new_value
        if [ -z "$new_value" ]; then
            echo "$current_value"
        else
            echo "$new_value"
        fi
    else
        read -p "Enter value: " new_value
        echo "$new_value"
    fi
}

echo "Step 1: Open Facebook Developers"
echo "Visit: https://developers.facebook.com/apps/"
echo ""
read -p "Press Enter when you're at the Facebook Developers page..."

echo ""
echo "Step 2: Find your App ID and App Secret"
echo "- Click on your app"
echo "- Go to Settings → Basic"
echo "- Copy App ID and App Secret"
echo ""

APP_ID=$(prompt_credential "FACEBOOK_APP_ID" "Facebook App ID:")
APP_SECRET=$(prompt_credential "FACEBOOK_APP_SECRET" "Facebook App Secret:")

echo ""
echo "Step 3: Generate Access Token"
echo "Visit: https://developers.facebook.com/tools/explorer/"
echo "- Select your app from dropdown"
echo "- Click 'Generate Access Token'"
echo "- Select permissions: instagram_basic, instagram_content_publish, instagram_manage_insights, pages_show_list, pages_read_engagement"
echo "- Click 'Generate Token'"
echo "- Copy the token"
echo ""
read -p "Press Enter when you have generated the access token..."

SHORT_TOKEN=$(prompt_credential "SHORT_TOKEN" "Short-lived Access Token:")

echo ""
echo "Step 4: Convert to Long-Lived Token"
echo "Running API call..."
echo ""

LONG_TOKEN_RESPONSE=$(curl -s "https://graph.facebook.com/v19.0/oauth/access_token?grant_type=fb_exchange_token&client_id=$APP_ID&client_secret=$APP_SECRET&fb_exchange_token=$SHORT_TOKEN")

LONG_TOKEN=$(echo $LONG_TOKEN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$LONG_TOKEN" ]; then
    echo "❌ Error converting to long-lived token:"
    echo "$LONG_TOKEN_RESPONSE"
    echo ""
    echo "Please check your App ID, App Secret, and Access Token."
    exit 1
fi

echo "✅ Long-lived token generated successfully!"
echo ""

echo "Step 5: Get Instagram Business Account ID"
echo "Getting your Facebook Pages..."
echo ""

PAGES_RESPONSE=$(curl -s "https://graph.facebook.com/v19.0/me/accounts?access_token=$LONG_TOKEN")
echo "Your Facebook Pages:"
echo "$PAGES_RESPONSE" | grep -o '"name":"[^"]*' | cut -d'"' -f4 | nl
echo ""

read -p "Enter the PAGE ID for the page connected to Instagram: " PAGE_ID

echo ""
echo "Getting Instagram Business Account ID..."
IG_RESPONSE=$(curl -s "https://graph.facebook.com/v19.0/$PAGE_ID?fields=instagram_business_account&access_token=$LONG_TOKEN")
IG_ACCOUNT_ID=$(echo $IG_RESPONSE | grep -o '"instagram_business_account":{"id":"[^"]*' | cut -d'"' -f6)

if [ -z "$IG_ACCOUNT_ID" ]; then
    echo "❌ Error: Could not find Instagram Business Account"
    echo "$IG_RESPONSE"
    echo ""
    echo "Make sure:"
    echo "- Your Instagram account is a Business account"
    echo "- It's connected to the Facebook Page you selected"
    exit 1
fi

echo "✅ Instagram Business Account ID: $IG_ACCOUNT_ID"
echo ""

echo "Step 6: Update .env file"
echo ""

cat > .opencode/.env << EOF
# Instagram API Credentials
# Generated on: $(date)

# Long-lived access token (expires after 60 days)
INSTAGRAM_ACCESS_TOKEN=$LONG_TOKEN

# Instagram Business Account ID
INSTAGRAM_BUSINESS_ACCOUNT_ID=$IG_ACCOUNT_ID

# Facebook App Credentials
FACEBOOK_APP_ID=$APP_ID
FACEBOOK_APP_SECRET=$APP_SECRET

# Optional: API Configuration
INSTAGRAM_API_VERSION=v19.0
LOG_LEVEL=INFO
EOF

echo "✅ Updated .opencode/.env with your credentials"
echo ""

echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "Your Instagram MCP is now configured!"
echo ""
echo "Test it by running:"
echo "  Get my Instagram profile information"
echo ""
echo "⚠️  IMPORTANT:"
echo "- Keep your .env file secure (already in .gitignore)"
echo "- Access token expires in 60 days"
echo "- Regenerate token when it expires"
echo ""

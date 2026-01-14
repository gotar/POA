# Instagram MCP Integration

This directory contains the local OpenCode configuration for Instagram MCP integration.

## Setup

### 1. Install Python 3.10+ and uvx

Make sure you have Python 3.10 or higher installed:

```bash
python3 --version  # Should be 3.10+
```

Install uvx if not already installed:

```bash
pip install uv
```

### 2. Configure Instagram API Credentials

Edit `.opencode/.env` and fill in your Instagram API credentials:

```bash
# Get credentials from: https://developers.facebook.com/apps/
INSTAGRAM_ACCESS_TOKEN=your_long_lived_access_token_here
INSTAGRAM_BUSINESS_ACCOUNT_ID=your_instagram_business_account_id
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
```

### 3. Getting Instagram API Credentials

Follow these steps to get your credentials:

1. **Instagram Business Account Setup**
   - Convert your Instagram account to Business Account (Settings → Account → Switch to Professional Account)
   - Connect to a Facebook Page

2. **Create Facebook App**
   - Go to [Facebook Developers](https://developers.facebook.com)
   - Create new app → Choose "Business"
   - Add "Instagram Graph API" product

3. **Get Access Token**
   - Use [Graph API Explorer](https://developers.facebook.com/tools/explorer)
   - Select your app
   - Generate Access Token with permissions:
     - `instagram_basic`
     - `instagram_content_publish`
     - `instagram_manage_insights`
     - `pages_show_list`
     - `pages_read_engagement`

4. **Convert to Long-Lived Token** (expires after 60 days):

```bash
curl -X GET "https://graph.facebook.com/v19.0/oauth/access_token?grant_type=fb_exchange_token&client_id={app_id}&client_secret={app_secret}&fb_exchange_token={short_lived_token}"
```

5. **Get Instagram Business Account ID**:

```bash
curl -X GET "https://graph.facebook.com/v19.0/{page-id}?fields=instagram_business_account&access_token={access_token}"
```

**Detailed Guide**: See [ig-mcp Authentication Guide](https://github.com/jlbadano/ig-mcp/blob/main/AUTHENTICATION_GUIDE.md)

### 4. Test the Connection

Start OpenCode in this project directory. The Instagram MCP will be automatically loaded.

Test with:
```
Get my Instagram profile information
```

## Available Commands

Once configured, you can use natural language commands:

### Profile Management
- "Get my Instagram profile info"
- "Show me my follower count"

### Media Management
- "Show me my last 10 Instagram posts"
- "Get engagement metrics for my recent posts"
- "Upload this image to Instagram with caption..."

### Analytics
- "What are my top performing posts this week?"
- "Show me engagement metrics for post {media_id}"

### Direct Messaging (Requires Advanced Access)
- "Show my Instagram DM conversations"
- "Read messages from conversation {conversation_id}"
- "Reply to {conversation_id} with message..."

## MCP Tools Available

The following tools are available via the Instagram MCP:

| Tool | Description | Required Access |
|------|-------------|-----------------|
| `get_profile_info` | Get Instagram business profile details | Standard |
| `get_media_posts` | Fetch recent posts with pagination | Standard |
| `get_media_insights` | Retrieve engagement metrics | Standard |
| `publish_media` | Upload images/videos to Instagram | Standard |
| `get_account_pages` | List connected Facebook pages | Standard |
| `get_conversations` | List Instagram DM conversations | **Advanced** |
| `get_conversation_messages` | Read messages from conversations | **Advanced** |
| `send_dm` | Reply to Instagram direct messages | **Advanced** |

## Rate Limits

Instagram API has the following rate limits:
- **Profile/Media requests**: 200 calls per hour
- **Publishing**: 25 posts per day
- **Insights**: 200 calls per hour

The MCP automatically handles rate limiting with exponential backoff.

## Advanced Access (Direct Messaging)

Direct messaging features require Meta App Review approval for Advanced Access to `instagram_manage_messages` permission.

See: [Instagram DM Setup Guide](https://github.com/jlbadano/ig-mcp/blob/main/INSTAGRAM_DM_SETUP.md)

## Troubleshooting

### "Invalid Access Token" Error
- Check if token has expired (60 days for long-lived tokens)
- Verify token has required permissions
- Regenerate long-lived token

### "Instagram account not found"
- Verify `INSTAGRAM_BUSINESS_ACCOUNT_ID` is correct
- Ensure Instagram account is connected to Facebook Page
- Confirm account is Business account, not Personal

### "Permission Denied"
- Review required permissions in Facebook App
- Re-generate access token with correct scopes
- Check if app is in Development vs Live mode

### MCP Not Loading
- Check Python version: `python3 --version` (needs 3.10+)
- Install uvx: `pip install uv`
- Check `.opencode/.env` has valid credentials
- Check logs: Set `LOG_LEVEL=DEBUG` in `.env`

## Security Notes

⚠️ **Important Security Practices**:
- Never commit `.opencode/.env` to version control (already in `.gitignore`)
- Rotate access tokens regularly
- Use HTTPS only
- Monitor API usage in Facebook Developer Console
- Keep `FACEBOOK_APP_SECRET` confidential

## Additional Resources

- [Instagram Graph API Documentation](https://developers.facebook.com/docs/instagram-api/)
- [ig-mcp GitHub Repository](https://github.com/jlbadano/ig-mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [OpenCode MCP Documentation](https://opencode.ai/docs/mcp-servers/)

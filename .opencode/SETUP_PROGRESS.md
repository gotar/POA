# Instagram MCP Setup Progress

## Completed Steps ✅

1. ✅ Created `.opencode/` directory structure
2. ✅ Created `opencode.json` with Instagram MCP configuration
3. ✅ Created `.env` template file
4. ✅ Updated project `.gitignore` to protect credentials
5. ✅ Created comprehensive README.md with setup instructions
6. ✅ Opened Facebook Developers registration page
7. ✅ Logged into Facebook account

## Current Step ⏳

**Developer Account Verification** (Manual step required)

You are currently at: `https://developers.facebook.com/async/registration/dialog/`

**Choose one verification method:**

### Option 1: Mobile Phone Verification
- Mobile number field shows: 608019078
- Click the blue button to send SMS code
- Enter the SMS code when received
- Click continue

### Option 2: Credit Card Verification
- Click "adding a credit card" link
- Enter credit card details
- Complete verification

## Next Steps (After Verification)

### 3. Complete Developer Registration
- Fill in Contact Info
- Fill in "About You" section
- Accept Terms & Conditions

### 4. Create Facebook App
- Click "Create App" button
- Choose "Business" type
- Fill in app details:
  - App Name: "POA Instagram MCP"
  - App Contact Email: (your email)
- Click "Create App"

### 5. Add Instagram Graph API Product
- In app dashboard, click "Add Product"
- Find "Instagram Graph API"
- Click "Set Up"

### 6. Generate Access Token (Graph API Explorer)
- Navigate to: https://developers.facebook.com/tools/explorer/
- Select your app from dropdown
- Click "Generate Access Token"
- Select permissions:
  - `instagram_basic`
  - `instagram_content_publish`
  - `instagram_manage_insights`
  - `pages_show_list`
  - `pages_read_engagement`
- Copy the generated token

### 7. Get Instagram Business Account ID

**Step 7a: Get your Facebook Pages**
```bash
curl -X GET "https://graph.facebook.com/v19.0/me/accounts?access_token=YOUR_ACCESS_TOKEN"
```

**Step 7b: Get Instagram Business Account ID from Page**
```bash
curl -X GET "https://graph.facebook.com/v19.0/PAGE_ID?fields=instagram_business_account&access_token=YOUR_ACCESS_TOKEN"
```

### 8. Convert to Long-Lived Token (60 days)
```bash
curl -X GET "https://graph.facebook.com/v19.0/oauth/access_token?grant_type=fb_exchange_token&client_id=YOUR_APP_ID&client_secret=YOUR_APP_SECRET&fb_exchange_token=YOUR_SHORT_LIVED_TOKEN"
```

### 9. Update .env File

Edit `.opencode/.env` with:
```bash
INSTAGRAM_ACCESS_TOKEN=your_long_lived_access_token
INSTAGRAM_BUSINESS_ACCOUNT_ID=your_instagram_business_account_id
FACEBOOK_APP_ID=your_app_id
FACEBOOK_APP_SECRET=your_app_secret
```

### 10. Test the Integration

Start OpenCode in this project and test:
```
Get my Instagram profile information
```

## Credentials Needed

- [ ] Facebook App ID
- [ ] Facebook App Secret  
- [ ] Instagram Access Token (long-lived)
- [ ] Instagram Business Account ID

## Troubleshooting

### Can't find Instagram Business Account ID
- Ensure Instagram is connected to a Facebook Page
- Verify Instagram account is "Business" not "Personal"
- Check in Instagram app: Settings → Account → Linked Accounts → Facebook

### Access Token Issues
- Tokens expire after 60 days
- Re-generate using Graph API Explorer
- Use token debugger: https://developers.facebook.com/tools/debug/accesstoken/

### Permission Errors
- Verify all required permissions are granted
- Check app is in "Live" mode (not Development)
- Regenerate token with correct scopes

## Useful Links

- Facebook App Dashboard: https://developers.facebook.com/apps/
- Graph API Explorer: https://developers.facebook.com/tools/explorer/
- Access Token Debugger: https://developers.facebook.com/tools/debug/accesstoken/
- Instagram Graph API Docs: https://developers.facebook.com/docs/instagram-api/

---

**Status**: Waiting for developer account verification

**Last Updated**: 2026-01-14 15:52

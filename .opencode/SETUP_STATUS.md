# Instagram MCP Setup - Final Status

## Completed Automatically ✅

1. ✅ **Created `.opencode/` directory structure**
2. ✅ **Created `opencode.json`** - Instagram MCP configuration using uvx
3. ✅ **Created `.env` template** - With all required credential fields
4. ✅ **Updated `.gitignore`** - Protects sensitive credentials
5. ✅ **Created `README.md`** - Comprehensive setup guide
6. ✅ **Created `SETUP_PROGRESS.md`** - Step-by-step tracker
7. ✅ **Created `setup-credentials.sh`** - Automated credential collection script
8. ✅ **Navigated to Facebook Developers** - Opened browser, logged in, started registration

## Blocked on Human Verification ⚠️

**Current State:** Facebook Developer registration requires SMS verification

- **SMS sent to:** 608 019 078 (Poland)
- **Browser waiting at:** https://developers.facebook.com/async/registration/dialog/
- **Action required:** Enter 6-digit SMS code

**Why automation stopped:**
- SMS verification is a security checkpoint requiring human intervention
- The code only exists on your physical phone
- Cannot be bypassed or automated

## To Complete Setup - Two Options

### Option A: Run Automated Script (Recommended)

After you complete SMS verification:

```bash
cd /home/gotar/Programowanie/POA
./opencode/setup-credentials.sh
```

This script will:
1. Guide you to get App ID and App Secret
2. Help you generate access token in Graph API Explorer
3. Automatically convert to long-lived token
4. Fetch your Instagram Business Account ID
5. Update `.opencode/.env` with all credentials

### Option B: Manual Setup

Follow the detailed steps in:
- `.opencode/README.md` - Complete setup guide
- `.opencode/SETUP_PROGRESS.md` - Step-by-step checklist

## What You Need to Do Right Now

### Step 1: Complete SMS Verification
1. Check phone 608 019 078
2. Find SMS from Facebook with 6-digit code
3. Enter code at: https://developers.facebook.com/async/registration/dialog/
4. Click "Continue"

### Step 2: Complete Registration
- Fill in Contact Info
- Fill in "About You"
- Accept terms

### Step 3: Create Facebook App
1. Go to https://developers.facebook.com/apps/
2. Click "Create App"
3. Choose "Business"
4. App Name: "POA Instagram MCP"
5. Contact Email: your email
6. Click "Create App"

### Step 4: Add Instagram Graph API
1. In app dashboard, click "Add Product"
2. Find "Instagram Graph API"
3. Click "Set Up"

### Step 5: Run the Script
```bash
./opencode/setup-credentials.sh
```

## Required Credentials

The script will collect and save to `.opencode/.env`:

- `FACEBOOK_APP_ID` - From app Settings → Basic
- `FACEBOOK_APP_SECRET` - From app Settings → Basic
- `INSTAGRAM_ACCESS_TOKEN` - Generated via Graph API Explorer (auto-converted to long-lived)
- `INSTAGRAM_BUSINESS_ACCOUNT_ID` - Auto-fetched from Facebook Page

## Testing the Integration

Once `.opencode/.env` is populated, test with:

```bash
# Start OpenCode in this directory
# Then run:
Get my Instagram profile information
```

## Files Created

```
.opencode/
├── opencode.json           # MCP server configuration
├── .env                    # Credentials (template - needs filling)
├── .gitignore             # Protects sensitive files
├── README.md              # Complete setup guide
├── SETUP_PROGRESS.md      # Step-by-step tracker
├── SETUP_STATUS.md        # This file
├── BLOCKED_ON_SMS.md      # SMS verification blocker details
└── setup-credentials.sh   # Automated credential collection
```

## Troubleshooting

### Can't receive SMS?
- Click "Send SMS Again"
- Or click "Update Mobile Number" and use credit card verification

### Don't have Instagram Business Account?
- Convert in Instagram app: Settings → Account → Switch to Professional → Business
- Connect to Facebook Page: Settings → Account → Linked Accounts → Facebook

### Need help with credentials?
- See `.opencode/README.md` section "Getting Instagram API Credentials"
- All URLs and curl commands provided

## Security Reminders

✅ `.opencode/.env` is in `.gitignore`
✅ Never commit credentials to git
✅ Access tokens expire after 60 days
✅ Keep App Secret confidential

---

**Status:** Setup 60% complete. Waiting for SMS verification to proceed.

**Next Action:** Check phone 608019078 for Facebook SMS code.

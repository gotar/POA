# Pi Browser Relay (Chrome extension → local CDP)

This tool lets you control an **existing Chrome tab** (your normal logged-in session) with tools like:

- `agent-browser` (`agent-browser connect http://127.0.0.1:18792`)
- Playwright (`chromium.connectOverCDP('http://127.0.0.1:18792')`)

It works by:

1. Starting a local **relay server** on loopback (`127.0.0.1`).
2. A Chrome MV3 extension attaches to the current tab via `chrome.debugger`.
3. The relay exposes a CDP endpoint (`/json/version` + `ws://.../cdp`) and forwards all CDP messages to/from the extension.

## Setup

### 1) Install deps

```bash
cd tools/pi-browser-relay
npm install
```

### 2) Start the relay

```bash
bin/pi-browser-relay
```

(or: `cd tools/pi-browser-relay && npm run start`)

### 3) Load the extension (unpacked)

Chrome → `chrome://extensions`

- Enable **Developer mode**
- **Load unpacked** → select: `tools/pi-browser-relay/extension`
- Pin the extension

### 4) Attach a tab

Open the tab you want to control, then click the extension icon.

- Badge shows `ON` when attached.

### 5) Connect with agent-browser

```bash
agent-browser connect http://127.0.0.1:18792
agent-browser snapshot
agent-browser click @e12
```

## Notes / security

- The relay binds to `127.0.0.1` and rejects non-loopback WebSocket upgrades.
- This is still powerful: attaching the extension gives automation full access to that tab’s session.
- Prefer a dedicated Chrome profile for automation.

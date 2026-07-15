# matugen-vars — Chrome Extension

Injects `--mat-*` CSS custom properties into all Chromium pages and web apps, with live updates (~1s) on wallpaper change. Replaces the Stylus global vars style for Chromium.

---

## Why this exists

Chromium has no equivalent to Firefox's `userContent.css`. The original solution was a Stylus global userstyle with `@updateURL` pointing to `http://localhost:9119/chromium-vars.user.css` — but Stylus enforces a minimum 30-minute update interval, so color changes after a wallpaper switch took up to 30 minutes to appear.

This extension cuts that to ~1 second.

---

## Architecture

```
Wallpaper change
    │
    ▼
matugen post-hook
    ├─ generates ~/.config/matugen/output/matugen-vars.css  (plain :root { --mat-* })
    └─ calls curl http://localhost:9119/notify               (increments server version counter)
                                │
                                ▼
                    matugen-server.py (port 9119)
                    ├─ GET /matugen-vars.css  → serves the file
                    ├─ GET /version           → returns current counter (integer)
                    └─ GET /notify            → increments counter, returns new value
                                │
                    ┌───────────┘ polls every 1s
                    ▼
              offscreen.js (persistent offscreen document)
              └─ sees version changed → sendMessage(VARS_CHANGED)
                                │
                    ┌───────────┘
                    ▼
              background.js (service worker)
              ├─ fetches /matugen-vars.css
              ├─ saves to chrome.storage.local['matVarsCss']
              └─ (executeScript fallback for pre-install tabs)
                                │
                    ┌───────────┘ storage.onChanged fires in every active tab
                    ▼
              content.js (runs in every page)
              └─ updates <style id="__matugen_vars__"> in the DOM live
```

**Key design decisions:**

- `offscreen.js` uses an [offscreen document](https://developer.chrome.com/docs/extensions/reference/api/offscreen) (not `chrome.alarms`) because MV3 alarms have a 1-minute minimum — unusable for near-instant updates.
- Live CSS injection uses `chrome.storage.onChanged` in `content.js`, not `chrome.tabs.sendMessage` (which fails for tabs opened before the extension was installed) and not `executeScript` alone (which is kept only as a fallback for those pre-install tabs).
- The server (`matugen_server.py`) adds CORS headers so the offscreen document can `fetch()` across origins.

---

## Files

| File | Role |
|---|---|
| `manifest.json` | MV3 manifest — declares permissions, content script, offscreen |
| `background.js` | Service worker — receives VARS_CHANGED, fetches CSS, stores it, executes fallback injection |
| `content.js` | Content script in every page — reads CSS from storage on load, listens for live updates via `storage.onChanged` |
| `offscreen.js` | Polls `/version` every 1s, sends VARS_CHANGED when counter changes |
| `offscreen.html` | Minimal HTML page that loads `offscreen.js` |

---

## Install (one-time)

1. Open `chrome://extensions`
2. Enable **Developer mode** (toggle top-right)
3. Click **Load unpacked**
4. Select `dotfiles/chromium-extension/matugen-vars/`

The extension injects `--mat-*` into all pages from now on. Stylus userstyles (WhatsApp, YouTube, etc.) reference those vars — no need to import a global vars style in Stylus for Chromium.

---

## Updating the extension

When `manifest.json` changes (new permissions, new files), the extension must be reloaded:

```
chrome://extensions → matugen vars → reload (↺ icon)
```

When only JS files change (logic updates), no reload is needed — the extension picks them up automatically.

---

## Required: matugen-server running

The extension polls `http://localhost:9119/version`. If the server is not running, polling fails silently and no live updates happen. Make sure the service is active:

```bash
systemctl --user status matugen-server.service
# If dead:
systemctl --user start matugen-server.service
```

See `post-install.md` step 5 for one-time setup.

---

## How Stylus per-site styles still work

Stylus userstyles (e.g. `youtube-matugen.user.css`, `whatsapp-matugen.user.css`) reference `var(--mat-primary)` etc. Those variables exist in every page because this extension injects them. The Stylus styles themselves don't need the global vars import anymore — the extension covers it.

The `chromium-vars.user.css` file (served at `/chromium-vars.user.css`) still exists and is still regenerated on every wallpaper change — it's used by Zen Browser's Stylus. For Chromium, the extension supersedes it.

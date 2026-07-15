# Post-Install Manual Configuration

Steps required after running `bootstrap.sh` + `deploy.sh`. Everything here is manual — bootstrap doesn't cover it.

---

## 1. Secrets and credentials

```bash
# Restore API keys
nano ~/.config/zsh/secrets.zsh
# Add: export GEMINI_API_KEY="..."

# Restore SSH keys
cp backup/backups/ssh/* ~/.ssh/
chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub

# Restore GPG keys
gpg --import backup/backups/gnupg/private.gpg

# Verify GitHub CLI auth
gh auth status
```

---

## 2. Machine-specific boot setup

```bash
# GRUB install — adjust device to your disk (e.g. /dev/nvme0n1, /dev/sda)
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB /dev/sdX
sudo grub-mkconfig -o /boot/grub/grub.cfg

# If safe.directory is wrong (external disk mounted at a different path):
git config --global --add safe.directory /new/path/to/Configuraciones
```

---

## 3. Spicetify

Spicetify paths change per machine. Run this after Spotify has launched at least once:

```bash
spicetify config spotify_path /opt/spotify
spicetify config prefs_path ~/.config/spotify/prefs
spicetify backup apply
```

---

## 4. AUR packages not in bootstrap

Some packages require manual AUR install post-bootstrap:

```bash
# Screen recording widget in the bar (gpu-screen-recorder service)
yay -S gpu-screen-recorder
```

---

## 5. matugen server (Stylus auto-update for Chromium)

The systemd user service is deployed by Stow with the matugen package, but needs to be enabled once:

```bash
systemctl --user daemon-reload
systemctl --user enable --now matugen-server.service
```

Serves `~/.config/matugen/output/` at `http://localhost:9119`. Required for Stylus in Chromium to auto-update `--mat-*` vars when the wallpaper changes.

---

## 6. Zen Browser — Stylus setup

1. Install the **Stylus** extension from Firefox Add-ons.
2. In `about:config`: set `toolkit.legacyUserProfileCustomizations.stylesheets = true`
   *(The matugen post-hook does this automatically on first run via `user.js`, but verify if styles don't load.)*
3. Import the **global vars style** (same file used by Chromium):
   - Stylus → Manage → Import
   - Select `~/.config/matugen/output/chromium-vars.user.css`
   - This injects `--mat-*` into all pages and auto-updates via `@updateURL` when the wallpaper changes.
4. Import all userstyles from `dotfiles/stylus/`:
   - Stylus → Manage → Import
   - Select each `*-matugen.user.css` file for the sites you use
5. In Stylus → **Settings** → enable **"Check for updates automatically"** (30 min interval is fine).

> **YouTube**: After importing `youtube-matugen.user.css`, disable **Cinematic/Ambient Mode** in YouTube settings (Settings → Playback and performance → Ambient mode → off). YouTube fills the ambient gradient canvas via JavaScript — CSS cannot override it, so the gradient would clash with the themed background if left enabled.
6. Run the matugen post-hook once to generate the CSS files:
   ```bash
   ~/.config/matugen/post-hook.sh
   ```
7. Reload Zen.

> **Why the global vars style?** `userContent.css` (Firefox's native mechanism) only loads at browser startup — it won't pick up wallpaper changes until Zen restarts. The Stylus global style auto-updates via the local HTTP server instead, so color changes apply without restarting the browser.

> **Requires dark mode** to be enabled in each app (WhatsApp, etc.) for the dark selectors to match.

---

## 7. Chromium — extension + Stylus setup for web apps

Web apps launched via `webapp-launch` (`chromium --app=<url>`) use Chromium's extension ecosystem. Stylus applies there, but `--mat-*` vars are now injected by a dedicated Chrome extension instead of a Stylus global style — this gives ~1s live updates instead of 30+ minutes.

**Steps (one-time):**

1. Install **Stylus** from the Chrome Web Store in Chromium.
2. `chrome://extensions` → Stylus → **Details** → enable **"Allow access to file URLs"**.
3. Install the **matugen-vars extension** (injects `--mat-*` vars into all pages and iframes, live):
   - `chrome://extensions` → enable **Developer mode**
   - **Load unpacked** → select `dotfiles/chromium-extension/matugen-vars/`
   - The extension uses `"all_frames": true` — required for iframes like YouTube live chat to receive `--mat-*` vars.
4. Import the userstyles for the sites you use as web apps:
   - Stylus → Manage → Import
   - Select each `*-matugen.user.css` from `dotfiles/stylus/`
5. In Stylus → **Settings** → enable **"Check for updates automatically"** (for per-site style updates from the local server).

> **YouTube**: See the YouTube note in step 6 — Cinematic Mode must be disabled in YouTube settings for the userstyle to work without visual artifacts.

> **No global vars Stylus import needed for Chromium.** The `matugen-vars` extension replaces it — it injects `--mat-*` into every page automatically. Stylus per-site styles (WhatsApp, YouTube, etc.) reference those vars and just work.

**How live updates work:**
- Wallpaper change → matugen post-hook generates `matugen-vars.css` → calls `/notify` on the local server
- Extension's offscreen document polls `/version` every 1s → detects the change
- Background service worker fetches the new CSS → saves to `chrome.storage.local`
- `content.js` in every active tab receives `storage.onChanged` → updates `<style>` in the DOM live — no page reload needed
- `matugen-server.service` (step 5 above) must be running

See `dotfiles/chromium-extension/matugen-vars/README.md` for full architecture details.

---

## 8. Web app launcher (`>webapp`)

The `>webapp` command in the launcher installs a site as a Chromium app. Chromium must be installed (bootstrap step 16 covers this). On first use it will download the favicon and create a `.desktop` entry automatically.

> Zen Browser is Firefox-based and does not support `--app=`. The launcher always falls back to `chromium` for web apps.

---

## 9. First matugen run

After everything is set up, trigger a full theme sync by changing the wallpaper in the launcher (`>wallpaper`), or run the post-hook directly:

```bash
~/.config/matugen/post-hook.sh
```

This regenerates all CSS files, reloads Kitty/btop/Hyprland, syncs SDDM, and updates the Chromium vars file.

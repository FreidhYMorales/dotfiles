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
6. Run the matugen post-hook once to generate the CSS files:
   ```bash
   ~/.config/matugen/post-hook.sh
   ```
7. Reload Zen.

> **Why the global vars style?** `userContent.css` (Firefox's native mechanism) only loads at browser startup — it won't pick up wallpaper changes until Zen restarts. The Stylus global style auto-updates via the local HTTP server instead, so color changes apply without restarting the browser.

> **Requires dark mode** to be enabled in each app (WhatsApp, etc.) for the dark selectors to match.

---

## 7. Chromium — Stylus setup for web apps

Web apps launched via `webapp-launch` (`chromium --app=<url>`) use Chromium's extension ecosystem. Stylus applies there too, but needs the `--mat-*` vars separately since Chromium has no `userContent.css`.

**Steps (one-time):**

1. Install **Stylus** from the Chrome Web Store in Chromium.
2. `chrome://extensions` → Stylus → **Details** → enable **"Allow access to file URLs"**.
3. Import the global vars style:
   - Stylus → Manage → Import
   - Select `~/.config/matugen/output/chromium-vars.user.css`
4. Import the userstyles for the sites you use as web apps (same files as Zen).
5. In Stylus → **Settings** → enable **"Check for updates automatically"** (30 min interval is fine).

**How auto-update works:**
- Each wallpaper change → matugen post-hook regenerates `chromium-vars.user.css`
- `chromium-vars.user.css` has `@updateURL http://localhost:9119/chromium-vars.user.css`
- Stylus fetches the new version from the local server on the next check cycle
- `matugen-server.service` (step 5 above) must be running

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

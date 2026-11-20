# Post-Install Manual Configuration

Steps required after running `bootstrap.sh` + `deploy.sh` that bootstrap can't safely automate (machine-specific paths, one-time browser extension setup, credentials).

---

## 0. Before and during the reinstall (unencrypted, archinstall)

Plain install without LUKS (the LUKS reinstall is story 21, deferred). Partitioning only happens from the
Arch live USB, before installing: `bootstrap.sh` runs afterwards, on the installed system, and adapts to
what it finds (`root_on_luks()` picks the plain path; no autologin).

Before booting the USB:

- Push the dotfiles repo (`git status` clean, `git push`); the external disk keeps a copy anyway.
- Back up anything outside `~/Files` you want to keep: `~/.ssh`, `~/.gnupg`, browser profiles, `~/Pictures/Wallpaper`.
- `~/Files` (today `nvme0n1p7`, label `Files`) survives only if it is **not** formatted below.

In `archinstall`:

- **Disk: manual partitioning.** Keep the ESP (format it or not, mount at `/boot/efi` or `/boot`;
  bootstrap asks `bootctl --print-esp-path`), a new ext4 root, and a **real swap partition** at least
  the size of RAM (30 GiB here; today 32.6 GiB): hibernation resumes from it and bootstrap writes its
  UUID into `resume=`. zram alone cannot hibernate. Mount the `Files` partition at
  `/home/deadlock/Files` **without formatting**. The Debian, Fedora and openSUSE partitions can go.
- **Encryption: none** (this path).
- **Bootloader: efistub with unified kernel images**, if the archinstall version offers it, so no GRUB is
  installed. Bootstrap rewrites `/etc/kernel/cmdline`, enables `default_uki` and creates the "Arch Linux"
  firmware entry first in the boot order either way.
- **Swap on zram: yes** (bootstrap keeps `zswap.enabled=0` for it; the swap partition is for hibernation).
- **User: `deadlock`** (SDDM, the notch greeter data dir and the PAM files assume it), with sudo.
- **Network: iwd** is enough to reach the internet; bootstrap sets up iwd + impala.

After the first boot: connect to Wi-Fi, run `install.sh` (or `curl ... | bash`), reboot, then the steps below.
Old firmware entries of the removed distros can be dropped with `sudo efibootmgr -b <num> -B`.

---

## 1. Secrets and credentials

```bash
# Verify GitHub CLI auth
gh auth status
```

> No hay backup de SSH/GPG keys vigente — si hace falta, generar/importar desde donde corresponda en cada máquina nueva.

---

## 2. Machine-specific boot setup

Nada manual: no hay bootloader. `bootstrap.sh` escribe el cmdline completo en `/etc/kernel/cmdline`, activa `default_uki` en `/etc/mkinitcpio.d/linux.preset` (UKI en `<ESP>/EFI/Linux/arch-linux.efi`, la ESP que reporta `bootctl --print-esp-path`) y crea la entrada "Arch Linux" del firmware con `efibootmgr`, primera en el orden de arranque (story 22). Verificar después del primer arranque:

```bash
efibootmgr          # BootCurrent = la entrada "Arch Linux"
cat /proc/cmdline   # el cmdline de /etc/kernel/cmdline
```

```bash
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

## 4. matugen server (Stylus auto-update for Chromium)

The systemd user service is deployed by Stow with the matugen package, but needs to be enabled once:

```bash
systemctl --user daemon-reload
systemctl --user enable --now matugen-server.service
```

Serves `~/.config/matugen/output/` at `http://localhost:9119`. Required for Stylus in Chromium to auto-update `--mat-*` vars when the wallpaper changes.

---

## 5. Zen Browser — Stylus setup

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

## 6. Chromium — extension + Stylus setup for web apps

Web apps launched via `webapp-launch` (`chromium --app=<url>`) use Chromium's extension ecosystem. Stylus applies there, but `--mat-*` vars are now injected by a dedicated Chrome extension instead of a Stylus global style — this gives ~1s live updates instead of 30+ minutes.

**Steps (one-time):**

1. Install **Stylus** from the Chrome Web Store in Chromium.
2. `chrome://extensions` → Stylus → **Details** → enable **"Allow access to file URLs"**.
3. Install the **matugen-vars extension** (injects `--mat-*` vars into all pages and iframes, live):
   - `chrome://extensions` → enable **Developer mode**
   - **Load unpacked** → select `dotfiles/chromium-extension/matugen-vars/`
   - The extension uses `"all_frames": true` — required for iframes like YouTube live chat to receive `--mat-*` vars.
4. Install the userstyles for the sites you use as web apps:
   - Open each `*-matugen.user.css` from `dotfiles/stylus/` in Chromium as a `file://` URL
     (e.g. `file:///path/to/Configuraciones/dotfiles/stylus/whatsapp-matugen.user.css`)
   - Stylus shows its install page: press **Install**
   - To pick up an edited style later, open the same URL and press **Reinstall**
     (the Import button on Stylus's Manage page does not update a style that is already installed)
5. In Stylus → **Settings** → enable **"Check for updates automatically"** (for per-site style updates from the local server).

> **YouTube**: See the YouTube note in step 6 — Cinematic Mode must be disabled in YouTube settings for the userstyle to work without visual artifacts.

> **No global vars Stylus import needed for Chromium.** The `matugen-vars` extension replaces it — it injects `--mat-*` into every page automatically. Stylus per-site styles (WhatsApp, YouTube, etc.) reference those vars and just work.

**How live updates work:**
- Wallpaper change → matugen post-hook generates `matugen-vars.css` → calls `/notify` on the local server
- Extension's offscreen document polls `/version` every 1s → detects the change
- Background service worker fetches the new CSS → saves to `chrome.storage.local`
- `content.js` in every active tab receives `storage.onChanged` → updates `<style>` in the DOM live — no page reload needed
- `matugen-server.service` (step 4 above) must be running

See `dotfiles/chromium-extension/matugen-vars/README.md` for full architecture details.

---

## 7. Web app launcher (`>webapp`)

The `>webapp` command in the launcher installs a site as a Chromium app. Chromium must be installed (bootstrap step 16 covers this). On first use it will download the favicon and create a `.desktop` entry automatically.

> Zen Browser is Firefox-based and does not support `--app=`. The launcher always falls back to `chromium` for web apps.

---

## 8. First matugen run

After everything is set up, trigger a full theme sync by changing the wallpaper in the launcher (`>wallpaper`), or run the post-hook directly:

```bash
~/.config/matugen/post-hook.sh
```

This regenerates all CSS files, reloads Kitty/btop/Hyprland, syncs SDDM, and updates the Chromium vars file.

---

## 9. Ollama — local models

Bootstrap installs Ollama, copies the repo's service drop-ins (`system/systemd/ollama.service.d/`) and enables `ollama.service`. It does not pull models (tens of GB); pull them by hand once the network is up.

Models live in the packaged default, `/var/lib/ollama` (owned by the `ollama` user, on `/`). The unit sets `OLLAMA_MODELS` there and `ProtectHome=yes`, so a path under `/home` would need its own drop-in. Space used today: about 29G (`sudo du -sh /var/lib/ollama`).

```bash
ollama pull qwen3-coder:30b   # 18 GB
ollama pull gpt-oss:20b       # 12 GB
ollama list                   # confirm both are back
```

Once pulled, models run with no network: `ollama run gpt-oss:20b "hi"` answers with Wi-Fi off.

### iGPU (Vulkan) vs CPU

Bootstrap installs `ollama-vulkan` and the repo's `igpu.conf` (`OLLAMA_IGPU_ENABLE=1`): without that setting Ollama logs "dropping integrated GPU" and runs on the CPU. Check with `ollama ps`: a loaded model shows `100% GPU`.

Measured on this ThinkPad (Core Ultra 200V, Arc 140V, 32 GB), on battery, `balanced` profile, 2026-11-20: `gpt-oss:20b`, fixed prompt, 200 tokens, temperature 0, two runs each. W is the mean of `/sys/class/power_supply/BAT0/power_now` while generating (whole system, screen on; idle was 4-6 W).

| Run | Speed | Battery draw |
|---|---|---|
| iGPU (default) | 22.0 tok/s | 8.6 W |
| CPU only | 11.3 tok/s | 12.1 W |

The iGPU is about twice as fast and draws less, so each token costs roughly a third of the energy (0.4 J against 1.1 J). It stays the default; to compare by hand, pass `"options": {"num_gpu": 0}` to `/api/generate` for a CPU-only run.

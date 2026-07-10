# dotfiles

Arch Linux · Hyprland · Quickshell · Neovim · Yazi

A fully automated setup for a fresh Arch install — one command and everything is configured.

---

## Stack

| Layer | Tool |
|---|---|
| WM | Hyprland |
| Shell | Quickshell (QML/Qt6) |
| Terminal | Kitty |
| Editor | Neovim |
| File manager | Yazi |
| Shell | zsh + Oh My Zsh |
| Color pipeline | matugen |
| Dotfile manager | GNU Stow |

---

## Install

### Fresh install — no repo on disk

```bash
curl -fsSL https://raw.githubusercontent.com/FreidhYMorales/dotfiles/main/install.sh | bash
```

With flags:

```bash
# Skip NVIDIA drivers (e.g. ThinkPad / AMD)
curl -fsSL https://raw.githubusercontent.com/FreidhYMorales/dotfiles/main/install.sh | bash -s -- --no-gpu

# Skip GRUB theme (e.g. systemd-boot)
curl -fsSL https://raw.githubusercontent.com/FreidhYMorales/dotfiles/main/install.sh | bash -s -- --no-grub
```

### Repo already on disk (external drive mounted)

```bash
./install.sh [--no-gpu] [--no-grub]
```

The script detects whether the repo is already present, clones it if not, and hands off to `dotfiles/bootstrap.sh`.

---

## What bootstrap does

27 steps, fully non-interactive:

1. Base tools (`git`, `base-devel`, `stow`, `unzip`)
2. yay (AUR helper)
3. Hyprland + Wayland stack + hyprpaper
4. GPU drivers — auto-detects NVIDIA / AMD / Intel (including hybrids) *(skipped with `--no-gpu`)*
5. zsh, Kitty, fish, Oh My Zsh + plugins
6. CLI tools (eza, bat, fd, ripgrep, fzf, lazygit, zellij, starship, rsync, aria2, p7zip, tealdeer, procs, dust, qrencode, poppler, gping…)
7. Neovim + Node.js, Python, Go, Rust, luarocks
8. Yazi + all previewers (imagemagick, ffmpeg, ffmpegthumbnailer, mediainfo…)
9. PipeWire + MPD + sof-firmware
10. Screenshot tools (grim, slurp, hyprpicker, satty)
11. Clipboard (cliphist, fuzzel)
12. Notifications + brightness (libnotify, swayosd, brightnessctl)
13. OCR (tesseract)
14. Screen recording (gpu-screen-recorder — AUR)
15. Theming (matugen, spicetify, spotify)
16. Apps (vesktop, zen-browser, mpv, libreoffice, nwg-displays)
17. Quickshell + Qt5/Qt6 Wayland
18. System utils (upower, ntfs-3g, power-profiles-daemon)
19. Fonts (Iosevka Term Nerd, Noto, Red Hat)
20. System info (btop, fastfetch)
21. SDDM + silent theme (with default custom config until matugen runs)
22. logind — power button: ignore short press, long press = poweroff
23. xdg-desktop-portal-termfilechooser (yazi as file picker)
24. Network (iwd + impala) + Bluetooth (bluez + bluetui)
25. Languages (Lua, Java/Maven, C++/Clang/CMake, Python extras, pnpm) + dev tools (git-delta, hyperfine, tokei, watchexec, xh, sqlite, docker)
26. AI tools (Claude Code, Gemini CLI, OpenCode, gentle-ai)
27. GRUB + Star Wars Posters theme + dual boot *(skipped with `--no-grub`)*

Ends by running `deploy.sh` (Stow), updating XDG dirs, rebuilding font cache, and installing Neovim/Yazi plugins.

---

## Structure

```
.
├── install.sh            ← curl-able entry point
├── dotfiles/             ← Stow packages (symlinked to $HOME)
│   ├── bootstrap.sh      ← full install script
│   ├── deploy.sh         ← stow all or specific packages
│   ├── nvim/             ← Neovim config
│   ├── yazi/             ← Yazi config + plugins
│   ├── zsh/              ← zsh + zshrc
│   ├── kitty/            ← Kitty terminal
│   ├── hypr/             ← Hyprland config
│   ├── quickshell/       ← Quickshell shell (bar, launcher, lock, dashboard…)
│   ├── git/              ← .gitconfig
│   ├── matugen/          ← color pipeline templates + post-hook
│   ├── scripts/          ← utility scripts
│   ├── fonts/            ← local fonts (~/.local/share/fonts/)
│   ├── vesktop/          ← Vesktop (Discord) config
│   ├── betterdiscord/    ← BetterDiscord theme
│   ├── mimeapps/         ← default apps
│   ├── termfilechooser/  ← yazi as xdg file picker
│   └── xdg-portal/       ← xdg-desktop-portal config
└── system/               ← sudo-level configs (not Stow)
    └── sddm/
        ├── themes/silent/    ← SDDM theme
        └── sddm.conf.d/      ← SDDM drop-in config
```

---

## Manual steps after bootstrap

Bootstrap prints a checklist at the end. Key items:

```bash
# 1. Restore secrets
echo 'export GEMINI_API_KEY="..."' >> ~/.config/zsh/secrets.zsh

# 2. Restore SSH keys
cp ~/path/to/backup/ssh/* ~/.ssh/
chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519

# 3. Restore GPG keys
gpg --import ~/path/to/backup/gnupg/public-keys.asc

# 4. GRUB install (machine-specific, run once)
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Deploy dotfiles only

```bash
cd dotfiles

./deploy.sh              # stow all packages
./deploy.sh nvim yazi    # stow specific packages
./deploy.sh --dry-run    # simulate without changes
```

---

## Color pipeline

matugen reads the current wallpaper and generates a Material You palette. A post-hook at `~/.config/matugen/post-hook.sh` propagates colors to: Kitty (live socket), btop (SIGUSR2), Hyprland (hyprctl), Zellij, Zen Browser, SDDM, and the Quickshell shell itself.

---

## License

Personal dotfiles — use what's useful, no warranty implied.  
The [SDDM silent theme](https://github.com/silentxxx/sddm-silent) retains its original license.

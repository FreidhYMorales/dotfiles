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
| Shell | zsh (pacman plugins + fzf-tab, no framework) |
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
# Skip GPU driver install entirely — ALL vendors, not just NVIDIA (VM, no
# real GPU, or managing drivers manually). Real hardware — including AMD,
# Intel, and hybrid setups — should run without this flag: bootstrap
# auto-detects and installs the right drivers for whatever's present.
curl -fsSL https://raw.githubusercontent.com/FreidhYMorales/dotfiles/main/install.sh | bash -s -- --no-gpu

```

### Repo already on disk (external drive mounted)

```bash
./install.sh [--no-gpu]
```

The script detects whether the repo is already present, clones it if not, and hands off to `dotfiles/bootstrap.sh`.

---

## What bootstrap does

Fully non-interactive, in this order:

0. pacman config, locale and timezone, `/etc/hosts` entry for the hostname
1. Base tools (`git`, `base-devel`, `stow`, `unzip`)
2. yay (AUR helper)
3. Hyprland + Wayland stack + hyprpaper
4. GPU drivers — auto-detects NVIDIA / AMD / Intel (including hybrids) *(skipped with `--no-gpu`)*, CPU microcode, Intel NPU driver when the device is present
5. zsh (autosuggestions, syntax highlighting, completions, fzf-tab), Kitty, fish, zoxide
6. CLI tools (eza, bat, fd, ripgrep, fzf, lazygit, zellij, starship, rsync, aria2, p7zip, tealdeer, procs, dust, qrencode, poppler, gping…)
7. Neovim + Node.js, Python, Go, Rust, luarocks
8. Yazi + all previewers (imagemagick, ffmpeg, ffmpegthumbnailer, mediainfo…)
9. PipeWire + MPD + sof-firmware
10. Screenshot tools (grim, slurp, hyprpicker, satty)
11. Clipboard (cliphist, fuzzel)
12. Notifications + brightness (libnotify, swayosd, brightnessctl)
13. OCR (tesseract)
14. Screen recording (gpu-screen-recorder — AUR)
15. Theming (matugen)
16. Apps (vesktop, zen-browser, chromium, obsidian, mpv, gimp, libreoffice, steam, nwg-displays…)
17. Quickshell + Qt5/Qt6 Wayland
18. System utils (upower, ntfs-3g, power-profiles-daemon), fwupd, and on laptops a 75/80% battery charge threshold and the PCIe ASPM policy
19. Firewall (ufw: deny incoming, allow outgoing)
20. zram (compressed swap)
21. Mirror ranking
22. Fonts (Iosevka Term Nerd, Noto, Red Hat) + monochrome icon theme
23. System info (btop, fastfetch)
24. SDDM + the notch-lock greeter (the notch shell's SDDM theme, fed by the notch)
25. logind — power button handled by Hyprland, lid suspends natively
26. xdg-desktop-portal-termfilechooser (yazi as file picker)
27. Network (iwd + impala) + Bluetooth (bluez + bluetui)
28. Languages (Lua, Java/Maven, C++/Clang/CMake, Python extras, pnpm) + dev tools (git-delta, hyperfine, tokei, watchexec, xh, sqlite, docker)
29. AI tools (Claude Code, OpenCode, Antigravity CLI via their native installers; Ollama; herdr)
30. Boot: Plymouth `bgrt` splash on a systemd initramfs, the whole kernel cmdline in `/etc/kernel/cmdline`, and a firmware entry (`efibootmgr`) that boots the UKI directly, with no bootloader
31. Boot optimization (masks `systemd-networkd-wait-online`, socket-activated cups)
32. Cybersecurity tools (nmap, wireshark, hashcat, john, metasploit, seclists, burpsuite…)

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
        └── sddm.conf.d/      ← SDDM drop-in config
```

---

## Manual steps after bootstrap

Bootstrap prints a checklist at the end. Key items:

```bash
# 1. Restore SSH keys
cp ~/path/to/backup/ssh/* ~/.ssh/
chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519

# 2. Restore GPG keys
gpg --import ~/path/to/backup/gnupg/public-keys.asc
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

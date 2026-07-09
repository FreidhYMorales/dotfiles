# System Package Reference

Derived from: nvim config (CONTEXT/), yazi config (docs/04_ECOSYSTEM.md),
scripts/.local/bin/*, dotfiles package inventory, and zsh functions.

Install order: base → AUR helper → Hyprland stack → tools → apps → dotfiles deploy.

---

## 0. Pre-AUR Bootstrap

These must exist before `yay` can be built:

```bash
sudo pacman -S --needed git base-devel
```

---

## 1. AUR Helper

```bash
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si
```

---

## 2. Hyprland / Wayland Stack

Already present in a Caelestia install — document here for clean reinstalls.

```bash
sudo pacman -S --needed \
  hyprland \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  uwsm \
  wayland-utils \
  qt6-wayland \
  polkit-gnome
```

> `uwsm` is required by `launch-or-focus` and `webapp-launch` scripts.

---

## 3. GPU — NVIDIA

```bash
sudo pacman -S --needed \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  libva-nvidia-driver
```

See `backup/references/caelestia/caelestia-patterns-reference.md` for NVIDIA
environment variables and Hyprland quirks.

---

## 4. Shell & Terminal

```bash
sudo pacman -S --needed \
  zsh \
  kitty \
  fish \
  zoxide
```

> `fish` is required by the `wsaction` script (workspace navigation).
> zsh is the interactive shell; fish is a runtime dep only (not the login shell).
> `zoxide` is initialized in `prompt.zsh` — required for `z` navigation.

### Oh My Zsh (framework)

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

> Zinit self-installs on first zsh launch (bootstrap code is already in `.zshrc`).

### Zsh plugins — git clone into OMZ custom/plugins

These 4 plugins are loaded via the `plugins=(...)` array in `.zshrc` and must
exist under `~/.oh-my-zsh/custom/plugins/`:

```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# zsh-256color
git clone https://github.com/chrissicool/zsh-256color \
  ~/.oh-my-zsh/custom/plugins/zsh-256color

# zsh-completions
git clone https://github.com/zsh-users/zsh-completions \
  ~/.oh-my-zsh/custom/plugins/zsh-completions
```

### Prompt — Powerlevel10k (p10k fallback)

Starship runs if installed (default). p10k activates as fallback if starship
is not present. p10k reads from `/usr/share/zsh-theme-powerlevel10k/`:

```bash
yay -S --needed zsh-theme-powerlevel10k
```

---

## 5. CLI Tools

### Core replacements (used in aliases.zsh and throughout)

```bash
sudo pacman -S --needed \
  eza \
  bat \
  fd \
  ripgrep \
  fzf \
  sd \
  duf \
  jq \
  lazygit \
  starship \
  zellij
```

| Tool | Replaces | Used by |
|------|----------|---------|
| `eza` | `ls` | aliases.zsh |
| `bat` | `cat` | bat.zsh, yazi fg plugin |
| `fd` | `find` | general use |
| `ripgrep` (`rg`) | `grep` | yazi fg plugin, nvim grug-far |
| `fzf` | — | yazi fg plugin, zsh completions |
| `sd` | `sed` | general use |
| `duf` | `df` | duf.zsh alias |
| `jq` | — | launch-or-focus, screenshot, record scripts |
| `lazygit` | — | nvim (snacks), yazi lazygit plugin |
| `starship` | — | optional prompt (p10k is primary) |
| `zellij` | tmux | terminal multiplexer |

---

## 6. Neovim

```bash
sudo pacman -S --needed neovim
```

### Neovim system dependencies

Mason installs LSP servers/formatters internally, but these runtimes must exist:

```bash
sudo pacman -S --needed \
  nodejs \
  npm \
  python \
  python-pip \
  go \
  rust \
  cargo \
  luarocks
```

> `luarocks` needed for `snacks.image` (requires `magick` rock: `luarocks install magick`).
> `go` needed for gopls + goimports (installed by mason, but `go` must be on PATH).
> `rust`/`cargo` needed for some mason tools and blink.cmp native compilation.

### Mason installs automatically (no manual action needed)

LSP servers: `lua_ls`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `gopls`,
`pyright`, `clangd`, `bashls`, `csharp_ls`, `angularls`, `emmet_ls`, `marksman`

Formatters: `prettier`, `stylua`, `black`, `isort`, `shfmt`, `clang-format`, `goimports`

Linters: `pylint`, `shellcheck`, `biome`, `cpplint`

---

## 7. Yazi

```bash
sudo pacman -S --needed yazi
```

### Yazi system dependencies

```bash
sudo pacman -S --needed \
  gvfs \
  gvfs-mtp \
  gvfs-backends \
  udisks2 \
  util-linux \
  fzf \
  ripgrep \
  bat \
  glow \
  hexyl \
  mediainfo \
  imagemagick \
  ffmpeg \
  ouch \
  lazygit \
  trash-cli \
  wl-clipboard
```

```bash
yay -S --needed rich-cli
```

### Yazi plugins (via `ya pkg`)

```bash
ya pkg add \
  imsi32/yatline \
  XYenon/clipboard \
  dedukun/relative-motions \
  Rolv-Apneseth/bypass \
  AnirudhG07/rich-preview \
  yazi-rs/plugins:piper \
  boydaihungst/mediainfo \
  ndtoan96/ouch \
  pirafrank/what-size \
  Lil-Dank/lazygit \
  uhs-robert/recycle-bin \
  boydaihungst/gvfs \
  yazi-rs/plugins:mount

# fg plugin (not in ya pkg registry — manual)
git clone https://github.com/DreamMaoMao/fg.yazi ~/.config/yazi/plugins/fg.yazi
```

---

## 8. Audio / Music

```bash
sudo pacman -S --needed \
  pipewire \
  pipewire-pulse \
  pipewire-alsa \
  pipewire-jack \
  wireplumber \
  mpd \
  ncmpcpp \
  wiremix
```

> `wiremix` — Quickshell audio mixer widget backend (dotfiles/wiremix/).
> `pipewire-pulse` — required by mpd (uses `pulse` audio output in config).
> mpd uses `/tmp/mpd.fifo` for ncmpcpp visualizer — no extra config needed.

---

## 9. Screenshot / Screen Tools

```bash
sudo pacman -S --needed \
  grim \
  slurp \
  hyprpicker \
  satty \
  wl-clipboard
```

> `hyprpicker` — used in `screenshot` and `ocr` scripts for freeze effect.
> `satty` — screenshot annotation editor (opened on notification click).

---

## 10. Clipboard

```bash
sudo pacman -S --needed \
  cliphist \
  fuzzel \
  wl-clipboard
```

Add to Hyprland autostart (`hyprland.conf`):
```ini
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```

---

## 11. Notifications / OSD

```bash
sudo pacman -S --needed \
  libnotify \
  swayosd
```

> `swayosd` — provides brightness/volume OSD (used by `brightness-display` and
> `brightness-keyboard` scripts via `swayosd-client`).
> A notification daemon (mako/dunst) is needed if not using Quickshell's built-in.
> When Quickshell is deployed, its WlSessionLock + notification widget replaces external daemons.

---

## 12. Brightness

```bash
sudo pacman -S --needed brightnessctl
```

---

## 13. OCR

```bash
sudo pacman -S --needed \
  tesseract \
  tesseract-data-eng
```

> For Spanish OCR support: `sudo pacman -S tesseract-data-spa`

---

## 14. Screen Recording

```bash
yay -S --needed gpu-screen-recorder-git
```

---

## 15. Theming / Colors

```bash
yay -S --needed \
  matugen \
  spicetify-cli
```

```bash
yay -S --needed spotify  # for spicetify
```

> See `backup/references/matugen-pipeline-reference.md` for full pipeline setup.

---

## 16. Quickshell

```bash
yay -S --needed quickshell-git
```

### Qt6 dependencies (usually pulled in automatically)

```bash
sudo pacman -S --needed \
  qt6-base \
  qt6-declarative \
  qt6-wayland \
  qt6-multimedia \
  qt6-svg
```

---

## 17. System Utils (battery, webapp scripts)

```bash
sudo pacman -S --needed \
  upower \
  curl \
  xdg-utils
```

```bash
yay -S --needed gum  # optional — TUI prompts in webapp-install/remove
```

---

## 18. Fonts

```bash
sudo pacman -S --needed \
  ttf-iosevkaterm-nerd \
  noto-fonts \
  noto-fonts-emoji \
  noto-fonts-cjk \
  ttf-nerd-fonts-symbols
```

> `ttf-iosevkaterm-nerd` — primary font (replaces Monocraft; used in kitty, Quickshell bar).
> `noto-fonts-emoji` — emoji fallback.
> `ttf-nerd-fonts-symbols` — icon-only Nerd Font (fallback for widgets).

---

## 19. System Info / Misc

```bash
sudo pacman -S --needed \
  btop \
  fastfetch \
  htop
```

---

## 20. Git Config

```bash
git config --global user.name "deadlock"
git config --global user.email "yannelmorales51@gmail.com"
```

---

## Full One-Liner (pacman only)

For quick reference — does not include AUR packages:

```bash
sudo pacman -S --needed \
  git base-devel \
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk uwsm wayland-utils qt6-wayland polkit-gnome \
  nvidia nvidia-utils nvidia-settings libva-nvidia-driver \
  zsh kitty fish zoxide \
  zsh-syntax-highlighting zsh-autosuggestions \
  eza bat fd ripgrep fzf sd duf jq lazygit starship zellij \
  neovim nodejs npm python python-pip go rust cargo luarocks \
  yazi gvfs gvfs-mtp gvfs-backends udisks2 util-linux glow hexyl mediainfo imagemagick ffmpeg ouch trash-cli \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber mpd ncmpcpp wiremix \
  grim slurp hyprpicker satty wl-clipboard cliphist fuzzel \
  libnotify swayosd brightnessctl \
  tesseract tesseract-data-eng \
  qt6-base qt6-declarative qt6-wayland qt6-multimedia qt6-svg \
  upower curl xdg-utils \
  ttf-iosevkaterm-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-nerd-fonts-symbols \
  btop fastfetch htop
```

## AUR One-Liner

```bash
yay -S --needed \
  yay \
  zsh-theme-powerlevel10k-git \
  rich-cli \
  gpu-screen-recorder-git \
  matugen \
  spicetify-cli \
  spotify \
  quickshell-git \
  gum
```

---

## Post-Install Checklist

- [ ] Install Oh My Zsh (`sh -c "$(curl ...)"`)
- [ ] Clone 4 zsh plugins into `~/.oh-my-zsh/custom/plugins/` (see section 4)
- [ ] `luarocks install magick` (for nvim snacks.image)
- [ ] `ya pkg add ...` (yazi plugins — see section 7)
- [ ] `git clone` fg.yazi plugin manually
- [ ] Set `GEMINI_API_KEY` in `~/.config/zsh/secrets.zsh`
- [ ] Restore GPG keys, SSH keys from `backup/backups/`
- [ ] `cd ~/Files/Configuraciones/dotfiles && ./deploy.sh --dry-run`
- [ ] Resolve Stow conflicts (btop, fastfetch, starship, hypr, yazi, nvim → Caelestia symlinks)
- [ ] Run `./deploy.sh`
- [ ] Add cliphist to Hyprland autostart (see section 10)

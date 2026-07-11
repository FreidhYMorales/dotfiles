#!/usr/bin/env bash
# bootstrap.sh — Full system setup for a fresh Arch Linux install.
# Installs all packages, configures shell, deploys dotfiles via Stow. (27 steps)
#
# Usage:
#   ./bootstrap.sh                        — full install (NVIDIA GPU, 1080p GRUB)
#   ./bootstrap.sh --no-gpu               — skip GPU drivers entirely (VM, manual install)
#   ./bootstrap.sh --no-grub              — skip GRUB theme + config (e.g. systemd-boot)
#   ./bootstrap.sh --grub-res=2560x1440   — GRUB theme at 2K resolution
#   ./bootstrap.sh --grub-res=3840x2160   — GRUB theme at 4K resolution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKIP_GPU=false
SKIP_GRUB=false
GRUB_RESOLUTION="1920x1080x32"

for arg in "$@"; do
  case "$arg" in
    --no-gpu)         SKIP_GPU=true ;;
    --no-grub)        SKIP_GRUB=true ;;
    --grub-res=*)     GRUB_RESOLUTION="${arg#--grub-res=}x32" ;;
  esac
done

step() { echo ""; echo "==> $*"; }

# Cache sudo credentials once and keep them alive for the full run
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# ── 1. Pre-AUR bootstrap ─────────────────────────────────────────────────────
step "Base tools"
sudo pacman -S --needed --noconfirm git base-devel stow unzip

# ── 2. AUR helper ────────────────────────────────────────────────────────────
step "yay"
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

# ── 3. Hyprland / Wayland ────────────────────────────────────────────────────
step "Hyprland stack"
sudo pacman -S --needed --noconfirm \
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  uwsm wayland-utils qt6-wayland polkit-gnome \
  hyprpaper

# ── 4. GPU ────────────────────────────────────────────────────────────────────
if [[ "$SKIP_GPU" == false ]]; then
  step "GPU drivers (auto-detect)"
  sudo pacman -S --needed --noconfirm pciutils

  GPU_INFO=$(lspci | grep -Ei "VGA|3D|Display")
  HAS_NVIDIA=false
  HAS_AMD=false
  HAS_INTEL=false

  if echo "$GPU_INFO" | grep -qi "nvidia";      then HAS_NVIDIA=true; fi
  if echo "$GPU_INFO" | grep -Eqi "amd|radeon"; then HAS_AMD=true;    fi
  if echo "$GPU_INFO" | grep -qi "intel";       then HAS_INTEL=true;  fi

  if [[ "$HAS_NVIDIA" == true ]]; then
    step "GPU: NVIDIA"
    sudo pacman -S --needed --noconfirm \
      nvidia nvidia-utils nvidia-settings libva-nvidia-driver
  fi

  if [[ "$HAS_AMD" == true ]]; then
    step "GPU: AMD"
    sudo pacman -S --needed --noconfirm \
      mesa vulkan-radeon libva-mesa-driver mesa-vdpau xf86-video-amdgpu
  fi

  if [[ "$HAS_INTEL" == true ]]; then
    step "GPU: Intel"
    sudo pacman -S --needed --noconfirm \
      mesa vulkan-intel intel-media-driver libva-intel-driver
  fi

  if [[ "$HAS_NVIDIA" == false && "$HAS_AMD" == false && "$HAS_INTEL" == false ]]; then
    echo "No recognized GPU found — skipping GPU drivers"
  fi
fi

# ── 5. Shell & Terminal ───────────────────────────────────────────────────────
step "Shell & terminal"
sudo pacman -S --needed --noconfirm zsh kitty fish zoxide

if [[ "$SHELL" != "$(which zsh)" ]]; then
  sudo usermod --shell "$(which zsh)" "$USER"
fi

step "Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

yay -S --needed --noconfirm zsh-theme-powerlevel10k

step "Zsh plugins"
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
declare -A ZSH_PLUGINS=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
  [zsh-256color]="https://github.com/chrissicool/zsh-256color"
  [zsh-completions]="https://github.com/zsh-users/zsh-completions"
)
for plugin in "${!ZSH_PLUGINS[@]}"; do
  [[ -d "$PLUGINS_DIR/$plugin" ]] || git clone "${ZSH_PLUGINS[$plugin]}" "$PLUGINS_DIR/$plugin"
done

# ── 6. CLI Tools ──────────────────────────────────────────────────────────────
step "CLI tools"
sudo pacman -S --needed --noconfirm \
  eza bat fd ripgrep fzf sd duf jq lazygit github-cli starship zellij \
  rsync aria2 p7zip tealdeer procs dust qrencode poppler

step "CLI tools: AUR"
yay -S --needed --noconfirm gping

# ── 7. Neovim ─────────────────────────────────────────────────────────────────
step "Neovim & runtimes"
sudo pacman -S --needed --noconfirm \
  neovim nodejs npm python python-pip go rust cargo luarocks

# ── 8. Yazi ───────────────────────────────────────────────────────────────────
step "Yazi"
sudo pacman -S --needed --noconfirm \
  yazi gvfs gvfs-mtp udisks2 util-linux \
  glow hexyl mediainfo imagemagick ffmpeg ffmpegthumbnailer ouch trash-cli wl-clipboard \
  python-pipx
pipx install rich-cli

# ── 9. Audio ──────────────────────────────────────────────────────────────────
step "Audio (PipeWire + MPD)"
# Remove known conflicting packages so pacman doesn't pause asking for confirmation
sudo pacman -R --noconfirm pulseaudio pulseaudio-bluetooth pipewire-media-session jack jack2 2>/dev/null || true
sudo pacman -S --needed --noconfirm \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
  mpd ncmpcpp wiremix sof-firmware

# ── 10. Screenshot & screen tools ────────────────────────────────────────────
step "Screenshot tools"
sudo pacman -S --needed --noconfirm \
  grim slurp hyprpicker satty wl-clipboard

# ── 11. Clipboard ─────────────────────────────────────────────────────────────
step "Clipboard"
sudo pacman -S --needed --noconfirm cliphist fuzzel

# ── 12. Notifications & brightness ───────────────────────────────────────────
step "Notifications & brightness"
sudo pacman -S --needed --noconfirm libnotify swayosd brightnessctl

# ── 13. OCR ───────────────────────────────────────────────────────────────────
step "OCR"
sudo pacman -S --needed --noconfirm tesseract tesseract-data-eng

# ── 14. Screen recording ──────────────────────────────────────────────────────
step "Screen recording"
yay -S --needed --noconfirm gpu-screen-recorder-git

# ── 15. Theming ───────────────────────────────────────────────────────────────
step "Theming (matugen + spicetify)"
yay -S --needed --noconfirm matugen spicetify-cli spotify

# ── 16. Apps ─────────────────────────────────────────────────────────────────
step "Apps"
yay -S --needed --noconfirm vesktop zen-browser-bin nordzy-cursors nordzy-hyprcursors nwg-displays
sudo pacman -S --needed --noconfirm mpv libreoffice-fresh

# ── 17. Quickshell ────────────────────────────────────────────────────────────
step "Quickshell"
yay -S --needed --noconfirm quickshell-git
sudo pacman -S --needed --noconfirm \
  qt6-base qt6-declarative qt6-wayland qt6-multimedia qt6-svg qt5-wayland

# ── 18. System utils ──────────────────────────────────────────────────────────
step "System utils"
sudo pacman -S --needed --noconfirm \
  upower curl xdg-utils xdg-user-dirs ntfs-3g power-profiles-daemon \
  geoclue python-gobject
yay -S --needed --noconfirm gum
sudo systemctl enable power-profiles-daemon

# ── 19. Fonts ─────────────────────────────────────────────────────────────────
step "Fonts"
sudo pacman -S --needed --noconfirm \
  ttf-iosevkaterm-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk \
  ttf-nerd-fonts-symbols
yay -S --needed --noconfirm redhat-fonts

# ── 20. System info ───────────────────────────────────────────────────────────
step "System info"
sudo pacman -S --needed --noconfirm btop fastfetch htop

# ── 21. SDDM ─────────────────────────────────────────────────────────────────
step "SDDM (display manager)"
sudo pacman -S --needed --noconfirm sddm qt6-virtualkeyboard

step "SDDM: install silent theme"
SDDM_THEME_SRC="$REPO_ROOT/system/sddm/themes/silent"
if [[ -d "$SDDM_THEME_SRC" ]]; then
  sudo cp -r "$SDDM_THEME_SRC" /usr/share/sddm/themes/
  sudo chown -R root:root /usr/share/sddm/themes/silent
  sudo chmod -R a+rX /usr/share/sddm/themes/silent
fi

step "SDDM: write config"
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$REPO_ROOT/system/sddm/sddm.conf.d/deadlock.conf" /etc/sddm.conf.d/

step "SDDM: bootstrap default custom config (replaced on first matugen run)"
sudo cp "$SDDM_THEME_SRC/configs/default.conf" /usr/share/sddm/themes/silent/configs/custom.conf

step "SDDM: enable service"
sudo systemctl enable sddm

# ── 22. logind — power button behavior ───────────────────────────────────────
step "logind: power button config"
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp "$REPO_ROOT/system/logind/logind.conf.d/deadlock.conf" /etc/systemd/logind.conf.d/
sudo systemctl restart systemd-logind 2>/dev/null || true

# ── 23. XDG portal — term file chooser ───────────────────────────────────────
step "xdg-desktop-portal-termfilechooser"
yay -S --needed --noconfirm xdg-desktop-portal-termfilechooser-hunkyburrito-git

# ── 24. Network & Bluetooth TUIs ─────────────────────────────────────────────
step "Network (iwd + impala)"
sudo pacman -S --needed --noconfirm iwd
yay -S --needed --noconfirm impala
sudo systemctl enable iwd

step "Bluetooth (bluez + bluetui)"
sudo pacman -S --needed --noconfirm bluez bluez-utils
yay -S --needed --noconfirm bluetui
sudo systemctl enable bluetooth

# ── 25. Programming languages & dev tools ────────────────────────────────────
# nodejs/npm, python, go, rust/cargo already installed in step 7 (Neovim runtimes)

step "Languages: Lua"
sudo pacman -S --needed --noconfirm lua

step "Languages: Java"
sudo pacman -S --needed --noconfirm jdk-openjdk maven

step "Languages: C++"
# gcc is in base-devel (step 1); add clang, cmake, debugger
sudo pacman -S --needed --noconfirm clang cmake gdb

step "Languages: Python extras"
sudo pacman -S --needed --noconfirm python-virtualenv
yay -S --needed --noconfirm uv

step "Languages: JavaScript extras"
sudo pacman -S --needed --noconfirm pnpm

step "Dev tools"
sudo pacman -S --needed --noconfirm \
  git-delta hyperfine tokei watchexec xh sqlite

step "Dev: Docker"
sudo pacman -S --needed --noconfirm docker docker-compose
sudo systemctl enable docker
sudo usermod -aG docker "$USER"

# ── 26. AI tools ─────────────────────────────────────────────────────────────
# step "AI tools"
# npm install -g @anthropic-ai/claude-code
# npm install -g @google/gemini-cli
# npm install -g opencode
# curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash

# ── 27. GRUB theme + dual boot ───────────────────────────────────────────────
if [[ "$SKIP_GRUB" == false ]]; then
  step "GRUB: packages"
  sudo pacman -S --needed --noconfirm grub efibootmgr os-prober

  step "GRUB: Star Wars Posters theme"
  GRUB_THEME_TMP="$(mktemp -d)"
  git clone --depth=1 \
    https://github.com/hashirsajid58200p/star-wars-posters-grub-theme \
    "$GRUB_THEME_TMP"
  THEME_DEST="/boot/grub/themes/StarWarsPosters"
  sudo mkdir -p "$THEME_DEST"
  sudo cp -r "$GRUB_THEME_TMP"/. "$THEME_DEST/"
  rm -rf "$GRUB_THEME_TMP"

  step "GRUB: configure theme + dual boot"
  GRUB_DEFAULTS="/etc/default/grub"
  # Theme + resolution (remove old entries first to avoid duplicates)
  sudo sed -i '/^GRUB_THEME=/d'   "$GRUB_DEFAULTS"
  sudo sed -i '/^GRUB_GFXMODE=/d' "$GRUB_DEFAULTS"
  printf 'GRUB_THEME="%s/theme.txt"\n' "$THEME_DEST" | sudo tee -a "$GRUB_DEFAULTS" > /dev/null
  printf 'GRUB_GFXMODE="%s"\n' "$GRUB_RESOLUTION"    | sudo tee -a "$GRUB_DEFAULTS" > /dev/null
  # OS prober — detects Windows and other distros
  if grep -q "^#\?GRUB_DISABLE_OS_PROBER" "$GRUB_DEFAULTS"; then
    sudo sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_DEFAULTS"
  else
    echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$GRUB_DEFAULTS" > /dev/null
  fi
  # Remember last selected OS across reboots
  sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' "$GRUB_DEFAULTS"
  grep -q "^GRUB_SAVEDEFAULT" "$GRUB_DEFAULTS" || \
    echo 'GRUB_SAVEDEFAULT=true' | sudo tee -a "$GRUB_DEFAULTS" > /dev/null
  # Longer timeout so dual boot is usable
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' "$GRUB_DEFAULTS"

  step "GRUB: regenerate config"
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# ── Deploy dotfiles ───────────────────────────────────────────────────────────
step "Deploying dotfiles"
# Remove auto-generated files that would conflict with Stow symlinks.
# These are created by tools installed above (OMZ → .zshrc, git → .gitconfig).
# On a fresh install there's nothing to preserve — our dotfiles replace them.
rm -f \
  "$HOME/.zshrc" \
  "$HOME/.zshenv" \
  "$HOME/.gitconfig"
"$SCRIPT_DIR/deploy.sh"

# ── Post-install ──────────────────────────────────────────────────────────────
step "Post-install: XDG user directories"
xdg-user-dirs-update

step "Post-install: font cache"
fc-cache -fv

step "Post-install: luarocks magick (nvim snacks.image)"
luarocks install --local magick \
  || echo "Warning: luarocks magick failed — install manually: luarocks install --local magick"

step "Post-install: yazi plugins"
if command -v ya &>/dev/null; then
  ya pack -i
  # plugins/ may not exist yet if the stow package has no tracked files there
  mkdir -p "$HOME/.config/yazi/plugins"
  if [[ ! -d "$HOME/.config/yazi/plugins/fg.yazi" ]]; then
    git clone https://github.com/DreamMaoMao/fg.yazi \
      "$HOME/.config/yazi/plugins/fg.yazi" 2>/dev/null \
      || echo "Warning: fg.yazi clone failed — install manually: git clone https://github.com/DreamMaoMao/fg.yazi ~/.config/yazi/plugins/fg.yazi"
  fi
fi

step "Post-install: MPD service"
systemctl --user enable --now mpd

step "Post-install: default Quickshell state"
mkdir -p "$HOME/.local/state/quickshell"
# Default wallpaper — Quickshell reads this on first launch
echo "$HOME/.config/hypr/assets/arch.png" > "$HOME/.local/state/quickshell/wallpaper.txt"
# Default theme state — dynamic:true so changing the wallpaper triggers matugen
echo '{"mode":"scheme-content","isLight":false,"dynamic":true}' > "$HOME/.local/state/quickshell/theme.json"
# weather-loc.json is NOT written here — get-location uses GeoClue2 (WiFi) automatically.
# To pin a location manually: echo '{"loc":"lat,lon","city":"Name"}' > ~/.local/state/quickshell/weather-loc.json

step "Post-install: matugen post-hook permissions"
chmod +x "$HOME/.config/matugen/post-hook.sh"

step "Post-install: termfilechooser wrapper"
chmod +x "$HOME/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh"

step "Post-install: SDDM theme sync helper + sudoers"
SDDM_SYNC_SRC="$HOME/.config/matugen/sddm-theme-sync"
if [[ -f "$SDDM_SYNC_SRC" ]]; then
  sudo cp "$SDDM_SYNC_SRC" /usr/local/bin/sddm-theme-sync
  sudo chown root:root /usr/local/bin/sddm-theme-sync
  sudo chmod 755 /usr/local/bin/sddm-theme-sync
fi
SUDOERS_FILE="/etc/sudoers.d/sddm-theme-sync"
if [[ ! -f "$SUDOERS_FILE" ]]; then
  echo "$USER ALL=(root) NOPASSWD: /usr/local/bin/sddm-theme-sync" | \
    sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Bootstrap complete."
echo ""
echo "Manual steps remaining:"
echo "  1. Set API keys:"
echo "       echo 'export GEMINI_API_KEY=\"...\"' >> ~/.config/zsh/secrets.zsh"
echo ""
echo "  2. Restore SSH keys:"
echo "       cp ~/Mio/Configuraciones/backup/backups/ssh/* ~/.ssh/"
echo "       chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519"
echo "       ssh -T git@github.com"
echo ""
echo "  3. Restore GPG keys:"
echo "       gpg --import ~/Mio/Configuraciones/backup/backups/gnupg/public-keys.asc"
echo ""
echo "  4. GitHub CLI:"
echo "       cp ~/Mio/Configuraciones/backup/backups/gh/* ~/.config/gh/"
echo "       gh auth status  # or: gh auth login"
echo ""
echo "  5. Spicetify — edit config after Spotify runs once:"
echo "       ~/.config/spicetify/config-xpui.ini → update spotify_path + prefs_path"
echo "       spicetify backup apply"
echo ""
echo "  6. Update safe.directory in ~/.gitconfig if disk path changed."
echo ""
echo "  7. GRUB install (machine-specific — run once after partitioning):"
echo "       sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
echo "     If Windows EFI files are missing from /boot/EFI/, restore them:"
echo "       cp -r ~/Mio/Configuraciones/backup/archive/restorations/probe-os/efi/Microsoft /boot/EFI/"
echo "       sudo grub-mkconfig -o /boot/grub/grub.cfg"

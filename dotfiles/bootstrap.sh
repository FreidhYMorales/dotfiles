#!/usr/bin/env bash
# bootstrap.sh — Full system setup for a fresh Arch Linux install.
# Installs all packages, configures shell, deploys dotfiles via Stow.
#
# Usage:
#   ./bootstrap.sh           — full install (NVIDIA GPU)
#   ./bootstrap.sh --no-gpu  — skip NVIDIA drivers (non-NVIDIA systems)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKIP_GPU=false

for arg in "$@"; do
  [[ "$arg" == "--no-gpu" ]] && SKIP_GPU=true
done

step() { echo ""; echo "==> $*"; }

# ── 1. Pre-AUR bootstrap ─────────────────────────────────────────────────────
step "Base tools"
sudo pacman -S --needed --noconfirm git base-devel stow

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
  step "NVIDIA drivers"
  sudo pacman -S --needed --noconfirm \
    nvidia nvidia-utils nvidia-settings libva-nvidia-driver
fi

# ── 5. Shell & Terminal ───────────────────────────────────────────────────────
step "Shell & terminal"
sudo pacman -S --needed --noconfirm zsh kitty fish zoxide

if [[ "$SHELL" != "$(which zsh)" ]]; then
  chsh -s "$(which zsh)"
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
  eza bat fd ripgrep fzf sd duf jq lazygit starship zellij

# ── 7. Neovim ─────────────────────────────────────────────────────────────────
step "Neovim & runtimes"
sudo pacman -S --needed --noconfirm \
  neovim nodejs npm python python-pip go rust cargo luarocks

# ── 8. Yazi ───────────────────────────────────────────────────────────────────
step "Yazi"
sudo pacman -S --needed --noconfirm \
  yazi gvfs gvfs-mtp gvfs-backends udisks2 util-linux \
  glow hexyl mediainfo imagemagick ffmpeg ffmpegthumbnailer ouch trash-cli wl-clipboard
yay -S --needed --noconfirm rich-cli

# ── 9. Audio ──────────────────────────────────────────────────────────────────
step "Audio (PipeWire + MPD)"
sudo pacman -S --needed --noconfirm \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
  mpd ncmpcpp wiremix

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

# ── 16. Quickshell ────────────────────────────────────────────────────────────
step "Quickshell"
yay -S --needed --noconfirm quickshell-git
sudo pacman -S --needed --noconfirm \
  qt6-base qt6-declarative qt6-wayland qt6-multimedia qt6-svg

# ── 17. System utils ──────────────────────────────────────────────────────────
step "System utils"
sudo pacman -S --needed --noconfirm upower curl xdg-utils xdg-user-dirs
yay -S --needed --noconfirm gum

# ── 18. Fonts ─────────────────────────────────────────────────────────────────
step "Fonts"
sudo pacman -S --needed --noconfirm \
  ttf-iosevkaterm-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk \
  ttf-nerd-fonts-symbols
yay -S --needed --noconfirm ttf-redhat-fonts

# ── 19. System info ───────────────────────────────────────────────────────────
step "System info"
sudo pacman -S --needed --noconfirm btop fastfetch htop

# ── 20. SDDM ─────────────────────────────────────────────────────────────────
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
sudo cp "$REPO_ROOT/system/sddm/sddm.conf.d/the_hyde_project.conf" /etc/sddm.conf.d/

step "SDDM: enable service"
sudo systemctl enable sddm

# ── 21. XDG portal — term file chooser ───────────────────────────────────────
step "xdg-desktop-portal-termfilechooser"
yay -S --needed --noconfirm xdg-desktop-portal-termfilechooser-hunkyburrito-git

# ── 22. Network & Bluetooth TUIs ─────────────────────────────────────────────
step "Network (iwd + impala)"
sudo pacman -S --needed --noconfirm iwd
yay -S --needed --noconfirm impala
sudo systemctl enable iwd

step "Bluetooth (bluez + bluetui)"
sudo pacman -S --needed --noconfirm bluez bluez-utils
yay -S --needed --noconfirm bluetui
sudo systemctl enable bluetooth

# ── Deploy dotfiles ───────────────────────────────────────────────────────────
step "Deploying dotfiles"
"$SCRIPT_DIR/deploy.sh"

# ── Post-install ──────────────────────────────────────────────────────────────
step "Post-install: XDG user directories"
xdg-user-dirs-update

step "Post-install: font cache"
fc-cache -fv

step "Post-install: luarocks magick (nvim snacks.image)"
luarocks install magick

step "Post-install: yazi plugins"
if command -v ya &>/dev/null; then
  ya pack -i
  if [[ ! -d "$HOME/.config/yazi/plugins/fg.yazi" ]]; then
    git clone https://github.com/DreamMaoMao/fg.yazi \
      "$HOME/.config/yazi/plugins/fg.yazi"
  fi
fi

step "Post-install: MPD service"
systemctl --user enable --now mpd

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

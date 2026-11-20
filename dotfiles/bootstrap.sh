#!/usr/bin/env bash
# bootstrap.sh — Full system setup for a fresh Arch Linux install.
# Installs all packages, configures shell, deploys dotfiles via Stow.
#
# Usage:
#   ./bootstrap.sh                        — full install (auto-detects NVIDIA/AMD/Intel via
#                                            lspci, installs drivers for whichever are present —
#                                            handles hybrid setups like Intel+AMD laptops too)
#   ./bootstrap.sh --no-gpu               — skip GPU driver install for ALL vendors, not just
#                                            NVIDIA (VM with no real GPU, or manual driver install)
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
    --no-gpu) SKIP_GPU=true ;;
    --no-grub) SKIP_GRUB=true ;;
    --grub-res=*) GRUB_RESOLUTION="${arg#--grub-res=}x32" ;;
    esac
done

step() {
    echo ""
    echo "==> $*"
}

# Cache sudo credentials once and keep them alive for the full run
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# ── 0. pacman config ──────────────────────────────────────────────────────────
step "pacman: color, parallel downloads, ILoveCandy"
sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
sudo sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 5/' /etc/pacman.conf
grep -q "^ILoveCandy" /etc/pacman.conf ||
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

step "pacman: enable multilib (32-bit libs — required by Steam)"
sudo sed -i '/^#\[multilib\]$/,/^#Include = \/etc\/pacman.d\/mirrorlist$/ s/^#//' /etc/pacman.conf
sudo pacman -Sy

# ── 0b. Locale & timezone ─────────────────────────────────────────────────────
step "Locale (en_US.UTF-8) + timezone (America/Guatemala)"
sudo sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sudo locale-gen
echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null
sudo timedatectl set-timezone America/Guatemala
sudo timedatectl set-ntp true

step "/etc/hosts: hostname entry"
# archinstall/pacstrap don't always add this. Without it, sudo hangs doing a
# hostname lookup for its audit log on EVERY invocation — slow always, and a
# real problem for anything sudo-based that runs during network transitions.
HOSTNAME_VALUE=$(cat /etc/hostname)
grep -q "$HOSTNAME_VALUE" /etc/hosts ||
    printf '127.0.1.1\t%s\n' "$HOSTNAME_VALUE" | sudo tee -a /etc/hosts >/dev/null

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

    if echo "$GPU_INFO" | grep -qi "nvidia"; then HAS_NVIDIA=true; fi
    if echo "$GPU_INFO" | grep -Eqi "amd|radeon"; then HAS_AMD=true; fi
    if echo "$GPU_INFO" | grep -qi "intel"; then HAS_INTEL=true; fi

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
            mesa vulkan-intel intel-media-driver libva-intel-driver \
            lib32-vulkan-intel vulkan-tools
    fi

    if [[ "$HAS_NVIDIA" == false && "$HAS_AMD" == false && "$HAS_INTEL" == false ]]; then
        echo "No recognized GPU found — skipping GPU drivers"
    fi
fi

# ── 4a. CPU microcode ─────────────────────────────────────────────────────────
# pacstrap leaves microcode out unless asked; GRUB picks it up on the
# grub-mkconfig run in step 30.
if grep -q GenuineIntel /proc/cpuinfo; then
    step "CPU microcode (Intel)"
    sudo pacman -S --needed --noconfirm intel-ucode
fi

# ── 4b. NPU (Intel AI Boost — Lunar Lake / Core Ultra 2xxV and newer) ─────────
# Independent of --no-gpu: this isn't a GPU, and a real NPU can be present
# even on a run that opts out of GPU driver install. Intel only ships
# official .deb releases (no native Arch build) — the AUR package repackages
# those same .deb payloads (driver-compiler, firmware, level-zero-npu) and
# adds its own udev rule granting the `render` group access to /dev/accel*
# (the .deb releases don't ship one at all — confirmed by inspecting
# v1.35.0's payload directly). Checked the actual PKGBUILD, not just AUR
# comments: no udev permission bug in the current package — that turned out
# to be about an older version. Real remaining gap: the AUR package trails
# upstream (pinned ~3 months behind latest at last check). Non-fatal — a
# missing/broken NPU driver shouldn't abort the rest of the bootstrap.
sudo pacman -S --needed --noconfirm pciutils
if lspci | grep -qi "Processing accelerators.*NPU"; then
    step "NPU: Intel AI Boost driver"
    yay -S --needed --noconfirm intel-npu-driver-bin || true
    # The udev rule grants the `render` group access to /dev/accel* — same
    # group Intel's GPU driver package creates for /dev/dri/renderD*, but it
    # ships with zero members. Without this, userspace can't touch the NPU
    # at all until logging in as root. Verified live: group existed, empty,
    # /dev/accel/accel0 unreachable by the normal user until added here.
    sudo usermod -aG render "$USER"
fi

# ── 5. Shell & Terminal ───────────────────────────────────────────────────────
step "Shell & terminal"
sudo pacman -S --needed --noconfirm zsh kitty fish zoxide

if [[ "$SHELL" != "$(which zsh)" ]]; then
    sudo usermod --shell "$(which zsh)" "$USER"
fi

step "Zsh plugins"
# .zshrc sources these from /usr/share/zsh/plugins; fzf-tab has no package in
# the official repos, so it is cloned to ~/.local/share/zsh/plugins.
sudo pacman -S --needed --noconfirm zsh-autosuggestions zsh-syntax-highlighting zsh-completions
[[ -d "$HOME/.local/share/zsh/plugins/fzf-tab" ]] ||
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$HOME/.local/share/zsh/plugins/fzf-tab"

# ── 6. CLI Tools ──────────────────────────────────────────────────────────────
step "CLI tools"
sudo pacman -S --needed --noconfirm \
    eza bat fd ripgrep fzf sd duf jq lazygit github-cli starship zellij \
    rsync caligula aria2 7zip tealdeer procs dust qrencode poppler \
    pacman-contrib transmission-cli atuin tree wget unrar man-db
sudo systemctl enable paccache.timer
# The zsh not-found handler looks commands up with `pacman -F`; the timer
# (pacman-contrib) keeps the files database fresh after this first download.
sudo pacman -Fy
sudo systemctl enable pacman-filesdb-refresh.timer

step "CLI tools: AUR"
yay -S --needed --noconfirm gping

# ── 7. Neovim ─────────────────────────────────────────────────────────────────
step "Neovim & runtimes"
sudo pacman -S --needed --noconfirm \
    neovim nodejs npm python python-pip go rust cargo luarocks tree-sitter-cli \
    python-pylatexenc

# ── 8. Yazi ───────────────────────────────────────────────────────────────────
step "Yazi"
sudo pacman -S --needed --noconfirm \
    yazi gvfs gvfs-mtp udisks2 util-linux \
    glow hexyl mediainfo imagemagick ffmpeg ffmpegthumbnailer ouch trash-cli wl-clipboard ripgrep-all \
    python-pipx
pipx install rich-cli

# ── 9. Audio ──────────────────────────────────────────────────────────────────
step "Audio (PipeWire + MPD)"
# Remove known conflicting packages so pacman doesn't pause asking for confirmation
sudo pacman -R --noconfirm pulseaudio pulseaudio-bluetooth pipewire-media-session jack jack2 2>/dev/null || true
sudo pacman -S --needed --noconfirm \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber alsa-utils \
    mpd mpd-mpris ncmpcpp wiremix sof-firmware playerctl

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
step "Theming (matugen)"
yay -S --needed --noconfirm matugen

# ── 16. Apps ─────────────────────────────────────────────────────────────────
step "Apps"
yay -S --needed --noconfirm vesktop zen-browser-bin chromium obsidian nordzy-cursors nordzy-hyprcursors nwg-displays
sudo pacman -S --needed --noconfirm mpv cava gimp yt-dlp swayimg zathura zathura-pdf-poppler libreoffice-fresh coin-or-mp gnome-keyring libsecret steam

# ── 17. Quickshell ────────────────────────────────────────────────────────────
step "Quickshell"
yay -S --needed --noconfirm quickshell-git
sudo pacman -S --needed --noconfirm \
    qt6-base qt6-declarative qt6-wayland qt6-multimedia qt6-svg qt5-wayland

# ── 18. System utils ──────────────────────────────────────────────────────────
step "System utils"
sudo pacman -S --needed --noconfirm \
    upower curl xdg-utils xdg-terminal-exec xdg-user-dirs ntfs-3g power-profiles-daemon \
    dosfstools exfatprogs ntfsprogs gptfdisk \
    geoclue python-gobject
yay -S --needed --noconfirm gum
sudo systemctl enable power-profiles-daemon

# ── 18b. Battery charge threshold (laptops only) ────────────────────────────
# Caps charging at 75-80% to slow battery wear — skipped on machines with no
# battery (BAT0 absent, e.g. desktops). auditorias/paquetes/README.md §1.1.
if [[ -d /sys/class/power_supply/BAT0 ]]; then
    step "Battery charge threshold (BAT0 75/80%)"
    sudo pacman -S --needed --noconfirm fwupd
    sudo tee /etc/tmpfiles.d/battery-thresholds.conf >/dev/null <<'EOF'
w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - 75
w /sys/class/power_supply/BAT0/charge_control_end_threshold - - - - 80
EOF
    sudo systemd-tmpfiles --create /etc/tmpfiles.d/battery-thresholds.conf
fi

# ── 18c. PCIe ASPM policy (laptops only) ─────────────────────────────────────
# Default policy leaves ASPM to BIOS/firmware, which often means no link power
# savings on idle PCIe devices (NVMe, WiFi). "powersave" is low-risk and
# measurable on battery. auditorias/optimizacion energy audit 2026-08-14 —
# thermald evaluated and discarded (DYTC already covers that role on this
# ThinkPad), auto-switch profile already covered by the udev rule above.
if [[ -d /sys/class/power_supply/BAT0 ]]; then
    step "PCIe ASPM policy (powersave)"
    sudo tee /etc/tmpfiles.d/pcie-aspm.conf >/dev/null <<'EOF'
w /sys/module/pcie_aspm/parameters/policy - - - - powersave
EOF
    sudo systemd-tmpfiles --create /etc/tmpfiles.d/pcie-aspm.conf
fi

# ── 19. Firewall ──────────────────────────────────────────────────────────────
step "Firewall (ufw)"
sudo pacman -S --needed --noconfirm ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo systemctl enable ufw
sudo ufw --force enable

# ── 20. zram (compressed swap) ───────────────────────────────────────────────
step "zram (compressed swap in RAM)"
sudo pacman -S --needed --noconfirm zram-generator
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0 2>/dev/null || true

# ── 21. Mirror ranking ────────────────────────────────────────────────────────
step "reflector (mirror ranking)"
sudo pacman -S --needed --noconfirm reflector
sudo tee /etc/xdg/reflector/reflector.conf >/dev/null <<'EOF'
--country Guatemala,Mexico,US
--protocol https
--latest 20
--sort rate
--save /etc/pacman.d/mirrorlist
EOF
sudo systemctl enable reflector.timer
sudo systemctl start reflector 2>/dev/null || true

# ── 22. Fonts ─────────────────────────────────────────────────────────────────
step "Fonts"
sudo pacman -S --needed --noconfirm \
    ttf-iosevkaterm-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk \
    ttf-nerd-fonts-symbols
# DepartureMono Nerd Font is the active quickshell font (services/Style.qml,
# Style.fontFamily) since the Iosevka -> DepartureMono migration — kept
# ttf-iosevkaterm-nerd above too (unused but harmless) rather than ripping
# it out while the pixel-font patch project is still in progress.
yay -S --needed --noconfirm redhat-fonts otf-departure-mono-nerd

# ── 22b. Icon theme (monochrome, for the Quickshell launcher) ────────────────
step "Icon theme: yet-another-monochrome-icon-set"
YAMIS_SRC="$HOME/.local/share/icons/yamis-src"
YAMIS_LIVE="$HOME/.local/share/icons/yamis-mono"
if [[ ! -d "$YAMIS_SRC" ]]; then
    git clone --depth 1 https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set.git "$YAMIS_SRC"
fi
if [[ -d "$YAMIS_SRC" ]]; then
    # Re-bake on every run (cheap, no network) in case the source was updated.
    rm -rf "$YAMIS_LIVE"
    cp -r "$YAMIS_SRC" "$YAMIS_LIVE"
    rm -rf "$YAMIS_LIVE/.git"
    # SVGs ship with fill:currentColor (a KDE Plasma-only auto light/dark
    # mechanism, FollowsColorScheme=true in index.theme) — outside Plasma that
    # resolves to CSS-default black. Bake a fixed opaque placeholder so the
    # shape renders at all; AppItem.qml recolors it live via MultiEffect.
    # Must be WHITE, not black: MultiEffect.colorization multiplies
    # colorizationColor by the source pixel's luminance, so a black (0
    # luminance) source always comes out black regardless of that color.
    find "$YAMIS_LIVE" -name '*.svg' -exec sed -i 's/currentColor/#FFFFFF/g' {} +
fi

# ── 23. System info ───────────────────────────────────────────────────────────
step "System info"
sudo pacman -S --needed --noconfirm btop fastfetch htop nvtop

# ── 24. SDDM ─────────────────────────────────────────────────────────────────
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
# Skip on a re-run over an already-configured system — otherwise this
# regresses the login theme back to stock colors until the next wallpaper
# change (same persistence-loss pattern as FRESH_WALLPAPER_STATE below).
if [[ -f /usr/share/sddm/themes/silent/configs/custom.conf ]]; then
    echo "custom.conf already exists — leaving current SDDM theme in place"
elif [[ -f "$SDDM_THEME_SRC/configs/default.conf" ]]; then
    sudo cp "$SDDM_THEME_SRC/configs/default.conf" /usr/share/sddm/themes/silent/configs/custom.conf
else
    echo "Warning: $SDDM_THEME_SRC/configs/default.conf not found — theme wasn't installed above, skipping custom.conf bootstrap"
fi

step "SDDM: enable service"
sudo systemctl enable sddm

# Fingerprint authentication (SDDM + Quickshell lockscreen) — auditorias/
# autenticacion/README.md has the full investigation. Three PAM services:
#   sddm               fingerprint optional, pam_unix always runs after it
#                      (fingerprint-only login used to leave the login
#                      keyring locked — pam_fprintd was `sufficient` in
#                      system-auth, short-circuiting past pam_unix)
#   quickshell-fprint  dedicated fprintd-only service for the lockscreen's
#                      second, parallel PamContext (either/or with password)
#   quickshell-password  the lockscreen's password PamContext — NOT the
#                      system "passwd" service, which still runs
#                      pam_fprintd first and would silently delay/bypass
#                      the ">security" fingerprint-enabled toggle
step "Fingerprint authentication: install fprintd + PAM services"
sudo pacman -S --needed --noconfirm fprintd
sudo cp "$REPO_ROOT/system/pam.d/sddm" /etc/pam.d/sddm
sudo cp "$REPO_ROOT/system/pam.d/quickshell-fprint" /etc/pam.d/quickshell-fprint
sudo cp "$REPO_ROOT/system/pam.d/quickshell-password" /etc/pam.d/quickshell-password

# TPM2 / Secure Boot prep — not wired into anything yet. Pre-staged tooling
# for a planned future migration to TPM2-backed disk unlock + Secure Boot.
# pamtester also doubles as the PAM debugging tool used throughout
# auditorias/autenticacion/README.md.
step "TPM2 tooling (Secure Boot migration prep)"
sudo pacman -S --needed --noconfirm clevis tpm2-tools
yay -S --needed --noconfirm pamtester

# ── 25. logind — power button behavior ───────────────────────────────────────
step "logind: power button config"
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp "$REPO_ROOT/system/logind/logind.conf.d/deadlock.conf" /etc/systemd/logind.conf.d/
# Restarting systemd-logind live kills the active graphical session (it owns
# session/seat tracking for whatever compositor SDDM started) — safe only on
# a fresh install with no session yet. Detect an active wayland/x11 session
# and skip the live restart when re-running on an already-installed desktop;
# the conf.d file is already written and takes effect on the next reboot.
# Types are collected first: `| grep -q` would exit on the first match and,
# under pipefail, the SIGPIPE it leaves on the next session turns "found"
# into "not found" — which restarted logind under a live desktop.
SESSION_TYPES=$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}' |
    xargs -I{} loginctl show-session {} -p Type --value 2>/dev/null || true)
if [[ $'\n'"$SESSION_TYPES"$'\n' =~ $'\n'(wayland|x11)$'\n' ]]; then
    echo "  → sesión gráfica activa detectada — se salta el restart en caliente (mataría la sesión). Aplica en el próximo reinicio."
else
    sudo systemctl restart systemd-logind 2>/dev/null || true
fi

step "systemd-sleep: suspend-then-hibernate delay"
sudo mkdir -p /etc/systemd/sleep.conf.d
sudo cp "$REPO_ROOT/system/systemd/sleep.conf.d/deadlock.conf" /etc/systemd/sleep.conf.d/

step "power-profiles-daemon: auto-switch profile on AC plug/unplug"
sudo mkdir -p /etc/udev/rules.d
sudo cp "$REPO_ROOT/system/udev/rules.d/90-power-profile-ac.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=power_supply

step "ThinkPad mute/micmute LEDs: uaccess so mute-toggle can drive them without sudo"
sudo mkdir -p /etc/udev/rules.d
sudo cp "$REPO_ROOT/system/udev/rules.d/92-mute-leds.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=leds

# ── 26. XDG portal — term file chooser ───────────────────────────────────────
step "xdg-desktop-portal-termfilechooser"
yay -S --needed --noconfirm xdg-desktop-portal-termfilechooser-hunkyburrito-git

# ── 27. Network & Bluetooth TUIs ─────────────────────────────────────────────
step "Network (iwd + impala)"
# wireless-regdb: regulatory domain, so iwd uses the right channels and power
sudo pacman -S --needed --noconfirm iwd wireless-regdb
yay -S --needed --noconfirm impala
sudo systemctl enable iwd

step "Bluetooth (bluez + bluetui)"
sudo pacman -S --needed --noconfirm bluez bluez-utils
yay -S --needed --noconfirm bluetui
sudo systemctl enable bluetooth

# ── 28. Programming languages & dev tools ────────────────────────────────────
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
    git-delta hyperfine tokei watchexec xh sqlite direnv \
    shellcheck shfmt actionlint gitleaks act trivy osv-scanner mise typst ast-grep go-yq
# Backups (engram-backup) and the DOTFILES IA tooling (pi-box) need these
sudo pacman -S --needed --noconfirm restic rclone socat

step "Dev: devices (Android + Arduino)"
sudo pacman -S --needed --noconfirm android-tools arduino-cli
yay -S --needed --noconfirm arduino-ide-bin

step "Dev: Docker"
sudo pacman -S --needed --noconfirm docker docker-compose
sudo systemctl enable docker
sudo usermod -aG docker "$USER"
yay -S --needed --noconfirm lazydocker

step "Virtualization (libvirt/QEMU) + remote desktop"
# Lab VMs (kali, metasploitable, windows server) under virt-manager; dnsmasq
# serves libvirt's default NAT network. freerdp/tigervnc reach the VMs and
# other machines; anydesk for remote support.
sudo pacman -S --needed --noconfirm libvirt qemu-desktop virt-manager dnsmasq freerdp tigervnc
sudo systemctl enable libvirtd
sudo usermod -aG libvirt "$USER"
yay -S --needed --noconfirm anydesk-bin

# ── 29. AI tools ─────────────────────────────────────────────────────────────
# Previously commented out: these used to abort the whole bootstrap run and
# leave everything after this step un-installed. Two real bugs killed it
# under `set -euo pipefail`: `npm install -g` without sudo fails (EACCES —
# this system's npm prefix is /usr, root-owned), and `opencode` isn't the
# real npm package name (404s; it's `opencode-ai`). Sidestepped entirely by
# using each tool's official native installer instead of npm — both
# Anthropic and OpenCode's own docs recommend the native/curl path over npm
# as of 2026 (self-contained binary, no Node.js runtime, no sudo/permission
# dance). gemini-cli and the gentle-ai installer script were dropped from
# this list — gemini-cli was superseded by Antigravity CLI below (same
# product family).
step "AI tools: Claude Code + OpenCode (native installers)"
# Guarded — each app self-updates on launch, no need to re-download every run.
command -v claude &>/dev/null || curl -fsSL https://claude.ai/install.sh | bash
command -v opencode &>/dev/null || curl -fsSL https://opencode.ai/install | bash

step "AI tools: Antigravity CLI (agy)"
# Standalone Go binary, not npm-based. Installer script's non-interactivity
# wasn't independently verified — watch the first real run of this step.
command -v agy &>/dev/null || curl -fsSL https://antigravity.google/cli/install.sh | bash

step "AI tools: Ollama"
sudo pacman -S --needed --noconfirm ollama
# Service tweaks from the repo (download.conf: one transfer stream per pull).
# Models stay in the packaged default, /var/lib/ollama (see post-install.md).
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo cp "$REPO_ROOT"/system/systemd/ollama.service.d/*.conf /etc/systemd/system/ollama.service.d
sudo systemctl daemon-reload
sudo systemctl enable ollama

step "AI tools: herdr (terminal workspace manager for coding agents)"
yay -S --needed --noconfirm herdr-bin

# ── 30. GRUB theme + dual boot ───────────────────────────────────────────────
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
    sudo sed -i '/^GRUB_THEME=/d' "$GRUB_DEFAULTS"
    sudo sed -i '/^GRUB_GFXMODE=/d' "$GRUB_DEFAULTS"
    printf 'GRUB_THEME="%s/theme.txt"\n' "$THEME_DEST" | sudo tee -a "$GRUB_DEFAULTS" >/dev/null
    printf 'GRUB_GFXMODE="%s"\n' "$GRUB_RESOLUTION" | sudo tee -a "$GRUB_DEFAULTS" >/dev/null
    # OS prober — detects Windows and other distros
    if grep -q "^#\?GRUB_DISABLE_OS_PROBER" "$GRUB_DEFAULTS"; then
        sudo sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_DEFAULTS"
    else
        echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$GRUB_DEFAULTS" >/dev/null
    fi
    # Always default to Arch (first menu entry — os-prober entries for other
    # distros always land after it, 10_linux runs before 30_os-prober) on
    # every boot, regardless of what was manually picked last time. Manually
    # selecting another OS at the menu still boots it for that one time —
    # GRUB just doesn't remember it afterward. `saved`+`GRUB_SAVEDEFAULT`
    # (the previous setting) did remember it, which is exactly the annoyance
    # of "tener que re-seleccionar Arch a cada rato" after booting into
    # another OS once.
    sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' "$GRUB_DEFAULTS"
    sudo sed -i '/^GRUB_SAVEDEFAULT/d' "$GRUB_DEFAULTS"
    # 3s — enough to select Windows on dual boot, fast enough on single boot
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$GRUB_DEFAULTS"
    # Quiet boot + disable NMI watchdog (saves ~200ms, reduces kernel log spam)
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nowatchdog"/' "$GRUB_DEFAULTS"

    step "Hibernation: resume= kernel param + mkinitcpio hook"
    # Swap partition detected at run time (not hardcoded) — a real reinstall
    # repartitions the disk, so any UUID baked in today would be stale on the
    # next fresh install. Excludes zram (never a valid hibernation target —
    # RAM-backed, gone on power loss) by only looking at "partition" swaps.
    SWAP_PART="$(swapon --show=NAME,TYPE --noheadings | awk '$2 == "partition" {print $1; exit}')"
    if [[ -n "$SWAP_PART" ]]; then
        SWAP_UUID="$(blkid -s UUID -o value "$SWAP_PART")"
        # mkinitcpio resume hook — must run after udev/block, before
        # filesystems, so the resume device is available when checked.
        if ! grep -qE '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf; then
            sudo sed -i 's/^\(HOOKS=.*\)\bblock\b/\1block resume/' /etc/mkinitcpio.conf
        fi
        # GRUB path (what actually boots this machine — confirmed via
        # `efibootmgr`, BootCurrent points at the "arch" grubx64.efi entry,
        # not the leftover UKI mkinitcpio also builds).
        if ! grep -q "resume=UUID=$SWAP_UUID" "$GRUB_DEFAULTS"; then
            sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 resume=UUID=$SWAP_UUID\"|" "$GRUB_DEFAULTS"
        fi
        # /etc/kernel/cmdline feeds the unused UKI at /boot/efi/EFI/Linux —
        # not the active boot path, but kept in sync in case that ever
        # changes (e.g. a future switch to systemd-boot).
        if [[ -f /etc/kernel/cmdline ]] && ! grep -q "resume=UUID=$SWAP_UUID" /etc/kernel/cmdline; then
            sudo sed -i "s/\$/ resume=UUID=$SWAP_UUID/" /etc/kernel/cmdline
        fi
        sudo mkinitcpio -P
    else
        echo "  → no se encontró una partición de swap real (solo zram) — se salta la config de hibernación"
    fi

    step "GRUB: regenerate config"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# ── 31. Boot optimization ────────────────────────────────────────────────────
step "Boot optimization: systemd services"
# systemd-networkd-wait-online blocks boot for 2+ min on desktop waiting for
# all interfaces — no desktop service needs full network before the session starts
sudo systemctl mask systemd-networkd-wait-online.service
# CUPS: socket activation — printer daemon starts on demand, not at every boot
sudo systemctl enable cups.socket 2>/dev/null || true
sudo systemctl disable cups.service 2>/dev/null || true

step "Boot optimization: journald limits"
# Without a size cap, journal flush at boot can take 1-2s and grow unbounded
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size.conf >/dev/null <<'EOF'
[Journal]
SystemMaxUse=50M
RuntimeMaxUse=20M
EOF

step "Boot optimization: mkinitcpio lz4 compression"
# lz4 decompresses faster than zstd at the cost of slightly larger initramfs —
# on SSD the decompression speed wins; kms hook handles Early KMS automatically
sudo sed -i 's/^#\?COMPRESSION=.*/COMPRESSION="lz4"/' /etc/mkinitcpio.conf
grep -q "^COMPRESSION_OPTIONS" /etc/mkinitcpio.conf &&
    sudo sed -i 's/^COMPRESSION_OPTIONS=.*/COMPRESSION_OPTIONS=(-9)/' /etc/mkinitcpio.conf ||
    echo 'COMPRESSION_OPTIONS=(-9)' | sudo tee -a /etc/mkinitcpio.conf >/dev/null
sudo mkinitcpio -P

step "Boot optimization: sysctl tuning"
sudo tee /etc/sysctl.d/99-performance.conf >/dev/null <<'EOF'
# Rarely swap with plenty of RAM — avoid latency spikes from swapping
vm.swappiness = 10
# Retain more dentries/inodes in RAM instead of reclaiming them aggressively
vm.vfs_cache_pressure = 50
# Start background writeback earlier, flush before hitting the hard limit
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
EOF
sudo sysctl -p /etc/sysctl.d/99-performance.conf

step "Boot optimization: noatime on root filesystem"
# noatime skips updating the access-time timestamp on every file read —
# eliminates unnecessary writes on SSD and reduces I/O overhead
ROOT_UUID=$(findmnt -no UUID /)
ROOT_TYPE=$(findmnt -no FSTYPE /)
if [[ -n "$ROOT_UUID" ]] && grep -q "$ROOT_UUID" /etc/fstab && ! grep -q "$ROOT_UUID.*noatime" /etc/fstab; then
    sudo sed -i "/$ROOT_UUID/s/defaults/defaults,noatime/" /etc/fstab
    sudo mount -o remount,noatime /
fi

# ── 32. Cybersecurity ────────────────────────────────────────────────────────
# Core toolset for HTB-style work (network recon, cracking, web testing,
# forensics/stego). Anything beyond this list installs on demand via AUR —
# deliberately NOT pulling in the full BlackArch repo (redundant with AUR,
# and its re-packaged versions of extra/AUR packages risk replacement
# conflicts on -Syu).
step "Cybersecurity"
sudo pacman -S --needed --noconfirm \
    nmap wireshark-qt tcpdump hashcat john metasploit binwalk perl-image-exiftool bandwhich \
    cfr mingw-w64-gcc
sudo usermod -aG wireshark "$USER"
yay -S --needed --noconfirm seclists burpsuite

# ── Deploy dotfiles ───────────────────────────────────────────────────────────
step "Deploying dotfiles"
# Remove auto-generated files that would conflict with Stow symlinks.
# Any pre-existing copy (from /etc/skel or an earlier setup) blocks Stow.
# On a fresh install there's nothing to preserve — our dotfiles replace them.
rm -f \
    "$HOME/.zshrc" \
    "$HOME/.zshenv" \
    "$HOME/.gitconfig"
"$SCRIPT_DIR/deploy.sh"

# Quickshell only enables QML tooling (qmlls import paths for Neovim) when an
# .qmlls.ini exists next to shell.qml; it then replaces it with a symlink to a
# generated config. Gitignored, so it has to be recreated on every install.
# -L too: a dangling symlink (stale /run target) must not be followed by touch.
QMLLS_INI="$HOME/.config/quickshell/.qmlls.ini"
[[ -e "$QMLLS_INI" || -L "$QMLLS_INI" ]] || touch "$QMLLS_INI"

# ── Post-install ──────────────────────────────────────────────────────────────
step "Post-install: XDG user directories"
xdg-user-dirs-update

step "Post-install: font cache"
fc-cache -fv

step "Post-install: yazi plugins"
if command -v ya &>/dev/null; then
    # Every third-party plugin (incl. lpnh/fr, which replaced the archived
    # fg.yazi git clone) is pinned in package.toml — no manual clones needed.
    ya pkg install ||
        echo "Warning: ya pkg install failed — run it manually later (a corrupt cache clears with rm -rf ~/.cache/yazi/packages)"
fi

step "Post-install: MPD service"
systemctl --user enable --now mpd mpd-mpris

step "Post-install: restore web apps"
webapp-restore || echo "Warning: webapp-restore failed — run it manually later"

step "Post-install: default Quickshell state"
mkdir -p "$HOME/.local/state/quickshell"
# Wallpapers.qml scans Paths.wallpapersDir (~/Pictures/Wallpaper) with a Qt
# FolderListModel — if the dir doesn't exist yet when Quickshell first
# launches, its filesystem watcher never attaches, and creating the dir
# later doesn't get picked up without a Quickshell/session restart. Create
# it now and seed the default wallpaper so it's there from the first launch.
mkdir -p "$HOME/Pictures/Wallpaper"
cp -n "$HOME/.config/hypr/assets/arch.png" "$HOME/Pictures/Wallpaper/arch.png"
# FRESH_WALLPAPER_STATE tracks whether this is a real fresh install (no
# wallpaper/theme chosen yet) — on a re-run over an already-configured
# system, don't reset the user's wallpaper/theme pick back to default.
FRESH_WALLPAPER_STATE=false
if [[ ! -f "$HOME/.local/state/quickshell/wallpaper.txt" ]]; then
    FRESH_WALLPAPER_STATE=true
    # Default wallpaper — Quickshell reads this on first launch
    echo "$HOME/Pictures/Wallpaper/arch.png" >"$HOME/.local/state/quickshell/wallpaper.txt"
fi
if [[ ! -f "$HOME/.local/state/quickshell/theme.json" ]]; then
    # Default theme state — dynamic:true so changing the wallpaper triggers matugen
    echo '{"mode":"scheme-content","isLight":false,"dynamic":true}' >"$HOME/.local/state/quickshell/theme.json"
fi

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
    echo "$USER ALL=(root) NOPASSWD: /usr/local/bin/sddm-theme-sync" |
        sudo tee "$SUDOERS_FILE" >/dev/null
    sudo chmod 440 "$SUDOERS_FILE"
fi

step "Post-install: generate theme from default wallpaper"
# The custom.conf bootstrapped above (step 24) is just the theme's stock
# default until matugen actually runs once — same command ColoursEngine.qml
# runs when a wallpaper is picked from the launcher, so first boot ends up
# themed identically to a manual pick instead of staying on stock colors.
# Only on a real fresh install — see FRESH_WALLPAPER_STATE above — otherwise
# this would re-theme everything back to the default wallpaper on a re-run.
if [[ "$FRESH_WALLPAPER_STATE" == true ]]; then
    matugen image "$HOME/Pictures/Wallpaper/arch.png" \
        --type scheme-content --mode dark --source-color-index 0 --quiet
    "$HOME/.config/matugen/post-hook.sh" dark
else
    echo "Skipping — wallpaper/theme already configured, not resetting to default"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Bootstrap complete."

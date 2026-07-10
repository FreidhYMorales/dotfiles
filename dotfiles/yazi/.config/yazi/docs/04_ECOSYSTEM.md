# Módulo 4 — Ecosistema (Plugins & Deps)

---

## 4.1 Inventario de Plugins

| # | Plugin | Repo | Setup() | Tipo de carga |
|---|--------|------|---------|---------------|
| 01 | yatline | `imsi32/yatline` | ✅ required | `require():setup()` |
| 02 | clipboard | `XYenon/clipboard` | ❌ | keybind-only |
| 03 | relative-motions | `dedukun/relative-motions` | ✅ required | `require():setup()` |
| 04 | bypass | `Rolv-Apneseth/bypass` | ❌ | keybind-only |
| 05 | fg | `DreamMaoMao/fg.yazi`* | ✅ required | `require():setup()` |
| 06 | gvfs | `boydaihungst/gvfs` | ✅ required | `require():setup()` |
| 07 | mount | `yazi-rs/plugins:mount` | ❌ | keybind-only |
| 08 | rich-preview | `AnirudhG07/rich-preview` | ❌ | previewer (yazi.toml) |
| — | piper | `yazi-rs/plugins:piper` | ❌ | previewer (yazi.toml) |
| 09 | glow | via piper | ❌ | previewer (yazi.toml) |
| 10 | hexyl | via piper | ❌ | previewer (yazi.toml) |
| 11 | mediainfo | `boydaihungst/mediainfo` | ❌ | previewer + keybind |
| 12 | ouch | `ndtoan96/ouch` | ❌ | previewer + keybind |
| 13 | what-size | `pirafrank/what-size` | ✅ optional | `require():setup()` |
| 14 | lazygit | `Lil-Dank/lazygit` | ❌ | keybind-only |
| 15 | recycle-bin | `uhs-robert/recycle-bin` | ✅ required | `require():setup()` |

*`fg` no está en el registry de `ya pkg` — requiere git clone manual.

---

## 4.2 Dependencias de Sistema

| Plugin | Herramienta(s) | Paquete Arch | Notas |
|--------|---------------|-------------|-------|
| yatline | — | — | Requiere Nerd Font en Kitty |
| clipboard | `wl-copy`, `wl-paste` | `wl-clipboard` | Ya disponible en Hyprland |
| fg | `fzf`, `rg`, `bat` | `fzf ripgrep bat` | Los tres son obligatorios |
| gvfs | `gio`, daemons gvfs | `gvfs gvfs-mtp gvfs-backends` | gvfs-mtp para Android/MTP |
| mount | `udisksctl`, `lsblk`, `eject` | `udisks2 util-linux` | udisks2 ya en Hyprland |
| rich-preview | `rich` | AUR: `rich-cli` o `pipx install rich-cli` | Python CLI |
| piper/glow | `glow` | `glow` | Markdown renderer |
| piper/hexyl | `hexyl` | `hexyl` | Hex viewer |
| mediainfo | `mediainfo`, `convert` | `mediainfo imagemagick` | `ffmpeg` opcional para thumbnails |
| ouch | `ouch` | `ouch` | Compresor/descompresor universal |
| lazygit | `lazygit` | `lazygit` | — |
| recycle-bin | `trash-put`, `trash-list` | `trash-cli` | — |

---

## 4.3 Script de Instalación Completa

```bash
#!/usr/bin/env bash
# install-yazi-deps.sh — Instala todas las dependencias del stack

set -e

echo "==> [1/4] Dependencias de pacman..."
sudo pacman -S --needed \
  gvfs gvfs-mtp gvfs-backends \
  udisks2 util-linux \
  fzf ripgrep bat \
  glow hexyl \
  mediainfo imagemagick ffmpeg \
  ouch \
  lazygit \
  trash-cli \
  wl-clipboard

echo "==> [2/4] Dependencias de AUR..."
yay -S --needed rich-cli

echo "==> [3/4] Plugins de Yazi (ya pkg)..."
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

echo "==> [4/4] fg plugin (git clone manual)..."
git clone https://github.com/DreamMaoMao/fg.yazi \
  ~/.config/yazi/plugins/fg.yazi

echo "==> Symlink de plugins..."
ln -sf ~/.config/yazi/plugins \
  /home/deadlock/Files/Configuraciones/yazi/plugins

echo "✓ Instalación completa."
```

**One-liner** (para instalaciones rápidas sin script):

```bash
sudo pacman -S --needed gvfs gvfs-mtp gvfs-backends udisks2 util-linux fzf ripgrep bat glow hexyl mediainfo imagemagick ffmpeg ouch lazygit trash-cli wl-clipboard && yay -S --needed rich-cli && ya pkg add imsi32/yatline XYenon/clipboard dedukun/relative-motions Rolv-Apneseth/bypass AnirudhG07/rich-preview yazi-rs/plugins:piper boydaihungst/mediainfo ndtoan96/ouch pirafrank/what-size Lil-Dank/lazygit uhs-robert/recycle-bin boydaihungst/gvfs yazi-rs/plugins:mount && git clone https://github.com/DreamMaoMao/fg.yazi ~/.config/yazi/plugins/fg.yazi
```

---

## 4.4 Actualización de Plugins

### Actualizar todos los plugins

```bash
ya pkg upgrade
```

### Actualizar un plugin específico

```bash
ya pkg upgrade <nombre>
# Ejemplo:
ya pkg upgrade imsi32/yatline
```

### Actualizar fg (manual)

```bash
cd ~/.config/yazi/plugins/fg.yazi && git pull
```

### Verificar versiones instaladas

```bash
# Lista plugins instalados con su versión
cat ~/.config/yazi/package.toml
```

---

## 4.5 Rollback de un Plugin

Si una actualización rompe algo:

```bash
# Ver commits del plugin
cd ~/.config/yazi/plugins/<plugin>.yazi
git log --oneline -10

# Volver a un commit anterior
git checkout <commit-hash>
```

Para plugins instalados via `ya pkg`, el directorio es `~/.config/yazi/plugins/<plugin>.yazi/` y es un repositorio git, por lo que `git checkout` funciona directamente.

---

## 4.6 Desinstalar un Plugin

```bash
# Via ya pkg
ya pkg remove <nombre>

# Manual
rm -rf ~/.config/yazi/plugins/<plugin>.yazi

# Luego eliminar:
# 1. require() / :setup() en init.lua
# 2. Keybinds en keymap.toml
# 3. Preloaders/previewers en yazi.toml (si aplica)
```

---

## 4.7 Verificar Estado del Stack

```bash
# Plugins instalados
ls ~/.config/yazi/plugins/

# Herramientas de sistema disponibles
which fzf rg bat glow hexyl mediainfo ouch lazygit trash-put wl-copy

# Symlink correcto
ls -la /home/deadlock/Files/Configuraciones/yazi/plugins
# debe mostrar: plugins -> /home/deadlock/.config/yazi/plugins
```

# Módulo 4 — Ecosistema (Plugins & Deps)

---

## 4.1 Inventario de Plugins

| # | Plugin | Repo | Setup() | Tipo de carga |
|---|--------|------|---------|---------------|
| 01 | yatline | `imsi32/yatline` | ✅ required | `require():setup()` |
| 02 | clipboard | `XYenon/clipboard` | ❌ | keybind-only |
| 03 | relative-motions | `boydaihungst/relative-motions`* | ✅ required | `require():setup()` |
| 04 | bypass | `Rolv-Apneseth/bypass` | ❌ | keybind-only |
| 05 | fr | `lpnh/fr`** | ⚪ optional (no se invoca) | keybind-only |
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
| 16 | git | `yazi-rs/plugins:git` | ✅ required | `require():setup()` + fetchers en yazi.toml |
| 17 | toggle-pane | `yazi-rs/plugins:toggle-pane` | ✅ required | — (keybind) |
| 18 | chmod | `yazi-rs/plugins:chmod` | ✅ required | — (keybind) |

\*Fork de `dedukun/relative-motions`: el original (sin mantenimiento desde 2025-07) usa `ya.mgr_emit`, removido en Yazi 26 (ver I-10). El fork usa `ya.emit`/`ui.render`, pero su autor también lo marca como sin mantenimiento.

\*\*Reemplaza a `DreamMaoMao/fg.yazi` (clone manual, archivado 2026-09, también usaba `ya.mgr_emit`). `fr` se instala con `ya pkg` y queda fijado en `package.toml` — ya no hay clone manual. `z` (búsqueda por nombre) usa el plugin `fzf` built-in de Yazi.

`orhnk/system-clipboard` se eliminó: era una dependencia muerta (nada lo usaba); el clipboard activo es `XYenon/clipboard`.

---

## 4.2 Dependencias de Sistema

| Plugin | Herramienta(s) | Paquete Arch | Notas |
|--------|---------------|-------------|-------|
| yatline | — | — | Requiere Nerd Font en Kitty |
| clipboard | `wl-copy`, `wl-paste` | `wl-clipboard` | Ya disponible en Hyprland |
| fr | `fzf`, `rg`, `bat`, `rga` | `fzf ripgrep bat ripgrep-all` | `ripgrep-all` solo para `g,R` (PDFs/documentos) |
| gvfs | `gio`, daemons gvfs | `gvfs gvfs-mtp gvfs-backends` | gvfs-mtp para Android/MTP |
| mount | `udisksctl`, `lsblk`, `eject` | `udisks2 util-linux` | udisks2 ya en Hyprland |
| rich-preview | `rich` | AUR: `rich-cli` o `pipx install rich-cli` | Python CLI |
| piper/glow | `glow` | `glow` | Markdown renderer |
| piper/hexyl | `hexyl` | `hexyl` | Hex viewer |
| mediainfo | `mediainfo`, `convert` | `mediainfo imagemagick` | `ffmpeg` opcional para thumbnails |
| ouch | `ouch` | `ouch` | Compresor/descompresor universal |
| lazygit | `lazygit` | `lazygit` | — |
| recycle-bin | `trash-put`, `trash-list` | `trash-cli` | — |
| git | `git` | `git` | — |

---

## 4.3 Script de Instalación Completa

```bash
#!/usr/bin/env bash
# install-yazi-deps.sh — Instala todas las dependencias del stack

set -e

echo "==> [1/3] Dependencias de pacman..."
sudo pacman -S --needed \
  gvfs gvfs-mtp gvfs-backends \
  udisks2 util-linux \
  fzf ripgrep ripgrep-all bat \
  glow hexyl \
  mediainfo imagemagick ffmpeg \
  ouch \
  lazygit \
  trash-cli \
  wl-clipboard

echo "==> [2/3] Dependencias de AUR..."
yay -S --needed rich-cli

echo "==> [3/3] Plugins de Yazi (ya pkg)..."
ya pkg add \
  imsi32/yatline \
  XYenon/clipboard \
  boydaihungst/relative-motions \
  Rolv-Apneseth/bypass \
  AnirudhG07/rich-preview \
  yazi-rs/plugins:piper \
  boydaihungst/mediainfo \
  ndtoan96/ouch \
  pirafrank/what-size \
  Lil-Dank/lazygit \
  uhs-robert/recycle-bin \
  boydaihungst/gvfs \
  yazi-rs/plugins:mount \
  lpnh/fr \
  yazi-rs/plugins:git \
  yazi-rs/plugins:toggle-pane \
  yazi-rs/plugins:chmod

echo "==> Symlink de plugins..."
ln -sf ~/.config/yazi/plugins \
  /home/deadlock/Files/Configuraciones/yazi/plugins

echo "✓ Instalación completa."
```

**One-liner** (para instalaciones rápidas sin script):

```bash
sudo pacman -S --needed gvfs gvfs-mtp gvfs-backends udisks2 util-linux fzf ripgrep ripgrep-all bat glow hexyl mediainfo imagemagick ffmpeg ouch lazygit trash-cli wl-clipboard && yay -S --needed rich-cli && ya pkg add imsi32/yatline XYenon/clipboard boydaihungst/relative-motions Rolv-Apneseth/bypass AnirudhG07/rich-preview yazi-rs/plugins:piper boydaihungst/mediainfo ndtoan96/ouch pirafrank/what-size Lil-Dank/lazygit uhs-robert/recycle-bin boydaihungst/gvfs yazi-rs/plugins:mount lpnh/fr yazi-rs/plugins:git yazi-rs/plugins:toggle-pane yazi-rs/plugins:chmod
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
which fzf rg rga bat glow hexyl mediainfo ouch lazygit trash-put wl-copy

# Symlink correcto
ls -la /home/deadlock/Files/Configuraciones/yazi/plugins
# debe mostrar: plugins -> /home/deadlock/.config/yazi/plugins
```

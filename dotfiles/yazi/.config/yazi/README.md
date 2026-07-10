# Yazi Config — Índice de Entrada

**Stack:** Arch Linux · Hyprland · Kitty · Zsh · Neovim (independiente)
**Versión Yazi:** 26.5.6
**Config root:** `/home/deadlock/Files/Configuraciones/yazi/`
**Activar:** `YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi`

---

## Módulos de Documentación

| # | Módulo | Archivo | Contenido |
|---|--------|---------|-----------|
| 1 | **Arquitectura** | [docs/01_ARCHITECTURE.md](docs/01_ARCHITECTURE.md) | Estructura, flujo de datos, independencia Neovim |
| 2 | **UI / init.lua** | [docs/02_UI.md](docs/02_UI.md) | Yatline, widgets, convenciones de color Lua |
| 3 | **Keymaps** | [docs/03_KEYMAPS.md](docs/03_KEYMAPS.md) | Tabla modal completa, lógica de binds, conflictos |
| 4 | **Ecosistema** | [docs/04_ECOSYSTEM.md](docs/04_ECOSYSTEM.md) | Inventario de plugins, deps, install script, updates |
| 5 | **Troubleshooting** | [docs/05_TROUBLESHOOTING.md](docs/05_TROUBLESHOOTING.md) | Logs, errores comunes, debug en runtime |

---

## Referencia Rápida — Archivos de Config

| Archivo | Propósito |
|---------|-----------|
| `yazi.toml` | Manager, openers, previewers, tasks |
| `keymap.toml` | Todos los keybinds (`[mgr]`, `[input]`, `[select]`) |
| `theme.toml` | Colores ANSI puros, transparencia nativa |
| `init.lua` | Setup de plugins, UI tweaks |
| `CONTEXT/INVARIANTS.md` | Reglas duras — leer antes de modificar |
| `CONTEXT/QUICK_REFERENCE.md` | Estado actual del stack |

---

## Setup en un Nuevo Sistema

```bash
# 1. Clonar / copiar config
git clone <repo> /home/deadlock/Files/Configuraciones/yazi

# 2. Symlink de plugins (OBLIGATORIO — ver I-00c)
ln -s ~/.config/yazi/plugins /home/deadlock/Files/Configuraciones/yazi/plugins

# 3. Instalar dependencias de sistema
sudo pacman -S gvfs gvfs-mtp gvfs-backends udisks2 \
  fzf ripgrep bat glow hexyl mediainfo imagemagick ffmpeg \
  ouch lazygit trash-cli wl-clipboard
yay -S rich-cli

# 4. Instalar plugins de Yazi
ya pkg add imsi32/yatline XYenon/clipboard dedukun/relative-motions \
  Rolv-Apneseth/bypass AnirudhG07/rich-preview yazi-rs/plugins:piper \
  boydaihungst/mediainfo ndtoan96/ouch pirafrank/what-size \
  Lil-Dank/lazygit uhs-robert/recycle-bin boydaihungst/gvfs \
  yazi-rs/plugins:mount
# fg: instalación manual (no está en el registry de ya pkg)
git clone https://github.com/DreamMaoMao/fg.yazi \
  ~/.config/yazi/plugins/fg.yazi

# 5. Activar
YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi
```

---

## Invariantes Críticos (resumen)

> Leer `CONTEXT/INVARIANTS.md` completo antes de modificar cualquier archivo.

- `[mgr]` en keymap.toml, **nunca** `[manager]`
- Theme vía flavor "deadlock" — cambios de color en el flavor, no en `theme.toml`
- Colores en init.lua/Lua: `"brightblack"` (sin guion)
- Plugin args: `plugin name arg`, **nunca** `plugin name --args=arg`
- `is = "..."` en filetype rules requiere `url` o `mime` acompañante (Yazi 26.x)
- `name =` en previewers/preloaders → renombrado a `url =` (Yazi 26.x)
- `tab_width` eliminado de `[manager]` en flavor (Yazi 26.x)
- Symlink `plugins/` es obligatorio para keybinds de plugin

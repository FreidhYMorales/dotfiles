# Caelestia — Patterns Reference

Personal config explored from `~/.config/caelestia/` (Arch Linux + Hyprland + Caelestia shell).
Config original en: [`config/`](config/)

---

## Top patterns

1. **postHook CLI** — theme-change trigger para sincronizar apps externas
2. **Multi-app theme sync en un solo script** — Obsidian + Notion (via zen chrome) en el mismo postHook
3. **Live kitty reload via sockets** — no reinicia kitty, descubre sockets en `/tmp/`
4. **Per-monitor `shell.json` overrides** — directorio `monitors/<name>/shell.json` para sobreescribir por pantalla
5. **Headless monitor + workspace fijo para WinApps** — workspace 6 en HEADLESS-1 para RDP
6. **`app2unit --` para lanzar apps** — cgroup tracking correcto desde keybinds
7. **Idle chain en 3 pasos** — lock → dpms off → suspend-then-hibernate

---

## Pattern 1 — postHook CLI para sincronizar themes

`cli.json` le dice a Caelestia qué script ejecutar cada vez que cambia el esquema de colores.

```json
// ~/.config/caelestia/cli.json
{
  "theme": {
    "postHook": "~/.config/caelestia/scripts/obsidian-theme-reload.sh"
  }
}
```

**Por qué vale:** un solo punto de entrada para propagar cambios de color a todas las apps.
Equivalente en dotfiles propios: un hook post-matugen/post-pywal que corra un script de sync.

---

## Pattern 2 — Multi-app theme sync (Obsidian + Notion/Zen)

El script `obsidian-theme-reload.sh` corre en cada cambio de tema y:
1. Copia el CSS generado por Caelestia a múltiples vaults de Obsidian
2. Copia el CSS de Notion al directorio `chrome/` de Zen Browser

```bash
# Fuente generada por Caelestia
SRC_OBSIDIAN="$HOME/.local/state/caelestia/theme/obsidian-theme.css"
SRC_NOTION="$HOME/.local/state/caelestia/theme/notion-theme.css"

# Propaga a cada vault
for vault in "${VAULTS[@]}"; do
    dest="$vault/.obsidian/themes/Caelestia"
    mkdir -p "$dest"
    cp "$SRC_OBSIDIAN" "$dest/theme.css"
    cp "$SRC_MANIFEST" "$dest/manifest.json"
done

# Propaga a Zen Chrome
cp "$SRC_NOTION" "$ZEN_CHROME/zen-notion.css"
```

**Por qué vale:** sin este script, cambiar de tema significa actualizar cada app a mano.
En dotfiles propios con matugen: misma idea, el script de postHook copia los templates renderizados.

---

## Pattern 3 — Live kitty reload sin reiniciar

Descubre todos los sockets activos de kitty en `/tmp/` y les manda los colores nuevos.

```bash
THEME="$HOME/.local/state/caelestia/theme/kitty-theme.conf"
[[ -f "$THEME" ]] || exit 0
for sock in /tmp/kitty-*; do
    [[ "$sock" =~ ^/tmp/kitty-[0-9]+$ ]] || continue
    kitten @ --to "unix:$sock" set-colors --all "$THEME" 2>/dev/null
done
```

**Por qué vale:** en dotfiles propios, el mismo patrón con `kitten @` funciona independientemente
de qué framework genera el tema (matugen, pywal, etc.).

---

## Pattern 4 — Template de colores para kitty con tokens M3

El template usa nombres de tokens de Material You en vez de paleta fija.
Caelestia los resuelve al renderizar. La idea es trasladable a cualquier template engine.

```conf
foreground              #{{ onSurface.hex }}
background              #{{ surface.hex }}
cursor                  #{{ secondary.hex }}
active_border_color     #{{ primary.hex }}
inactive_border_color   #{{ outlineVariant.hex }}
# terminales
color0  #{{ term0.hex }}
...
color15 #{{ term15.hex }}
```

Tokens semánticos relevantes para dotfiles propios:
`primary`, `secondary`, `tertiary`, `surface`, `onSurface`, `surfaceContainer`,
`surfaceContainerHigh`, `onSurfaceVariant`, `outlineVariant`, `error`.

---

## Pattern 5 — Headless monitor + workspace fijo para WinApps

Crea un monitor headless al inicio y fija el workspace 6 en él.
Las ventanas de Office/Windows van ahí — evitan mezclar con workspaces reales.

```conf
# hypr-user.conf
exec-once = hyprctl output create headless
monitor = HEADLESS-1, 1920x1080@60, 1600x0, 1

# hyprland/rule.conf
workspace = 6, monitor:HEADLESS-1, default:true
windowrule = opaque true, match:class Microsoft (Excel|Word|Outlook|PowerPoint|Windows)
windowrule = no_blur true, match:class Microsoft (Excel|Word|Outlook|PowerPoint|Windows)
windowrule = float true, match:class Microsoft (Excel|Word|Outlook|PowerPoint|Windows)
```

---

## Pattern 6 — app2unit para keybinds

`app2unit --` envuelve el comando para que la app quede en su propio cgroup systemd.
Sin esto, las apps lanzadas desde Hyprland quedan en el cgroup del WM.

```conf
bind = Super+Alt, E, exec, app2unit -- $fileExplorer
```

---

## Pattern 7 — Idle chain escalonada

Tres timeouts encadenados: pantalla bloqueada primero, luego apagar display, luego suspend.

```json
"timeouts": [
    { "idleAction": "lock",                              "timeout": 180 },
    { "idleAction": "dpms off", "returnAction": "dpms on", "timeout": 300 },
    { "idleAction": ["systemctl", "suspend-then-hibernate"], "timeout": 600 }
]
```

`inhibitWhenAudio: true` — no duerme mientras hay audio reproduciéndose.

---

## Fixes críticos para NVIDIA + Wayland

Documentados en `hyprland/env.conf` y `hyprland/nvidia.conf`. Reproducir en cualquier setup con NVIDIA.

```conf
# Fix screencopy / PipeWire en NVIDIA
env = AQ_NO_MODIFIERS, 1

# Icon theme para Quickshell
env = QS_ICON_THEME, Papirus-Dark

# NVIDIA stack
env = LIBVA_DRIVER_NAME, iHD
env = NVD_BACKEND, direct          # requiere libva-nvidia-driver
env = GBM_BACKEND, nvidia-drm
cursor:no_hardware_cursors = true  # evita hitches al cambiar cursor
```

---

## Config values worth reusing (shell.json)

### Fuentes
```
IosevkaTerm Nerd Font       ← sans, clock
IosevkaTerm Nerd Font Mono  ← mono
Material Symbols Sharp      ← iconos
```

### Bar layout (orden real)
```
logo → workspaces → spacer → activeWindow → spacer → tray → clock → statusIcons → power
```

Opciones no obvias:
- `showOnHover: true` — barra autohide
- `bar.tray.compact: true` + `bar.activeWindow.compact: true`
- `bar.workspaces.perMonitorWorkspaces: true`
- `bar.workspaces.shown: 5`

### Window rules útiles

```conf
# nmtui en kitty flotante centrado
windowrule = float true, match:class kitty, match:title nmtui
windowrule = size 60% 70%, match:class kitty, match:title nmtui
windowrule = center 1, match:class kitty, match:title nmtui

# Obsidian frosted glass
windowrule = opacity 0.75, match:class obsidian

# Zen browser leve transparencia
windowrule = opacity 0.9 0.9, match:class zen-browser
```

### Animaciones MD3

```conf
bezier = md3_decel, 0.05, 0.7, 0.1, 1
bezier = easeOutExpo, 0.16, 1, 0.3, 1

animation = windows,          1, 3,   md3_decel, popin 60%
animation = workspaces,       1, 3.5, easeOutExpo, slide
animation = specialWorkspace, 1, 3,   md3_decel, slidevert
animation = fade,             1, 2.5, md3_decel
```

### Keyboard

```conf
kb_variant = altgr-intl     ← accents sin Dead keys
numlock_by_default = true
```

### XWayland scaling (Steam, apps legadas)

```conf
xwayland {
    force_zero_scaling = true
}
```

---

## Startup sequence (hypr-user.conf)

```conf
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = gnome-keyring-daemon --start --components=secrets
exec-once = /usr/lib/xdg-desktop-portal-termfilechooser
exec-once = /usr/lib/kdeconnectd
exec-once = kdeconnect-indicator
exec-once = hyprctl output create headless
```

---

## Zen browser — color sync script

`scripts/update-zen-colors.sh` lee el scheme actual de Caelestia y genera CSS vars:

```bash
get_color() {
    grep "^\$$1 = " "$SCHEME" | awk '{print $3}'
}
# Genera: --c-accent, --c-text, --c-mantle, --c-base, --c-surface0, --c-surface1
```

Con matugen, el equivalente es leer el `colors.json` generado y renderizar el mismo CSS.

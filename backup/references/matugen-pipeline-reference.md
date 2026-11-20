# Pipeline de Colores — Referencia

Documentación del pipeline de theming real (matugen + Quickshell), verificada contra `dotfiles/matugen/.config/matugen/config.toml` y `post-hook.sh`.

---

## 1. Tokens Material You disponibles

Tokens que expone `colors.json` (snake_case, ej. `surface_container`), accesibles en templates como `{{colors.<token>.hex}}` / `.hex_stripped` / `.rgb` / `.rgba`.

### Colores base M3

| Token | Uso |
|---|---|
| `primary` | Acción principal, bordes activos |
| `on_primary` | Texto sobre primary |
| `primary_container` | Contenedor de primary (más oscuro) |
| `on_primary_container` | Texto sobre primary_container |
| `secondary` | Acción secundaria |
| `on_secondary` / `secondary_container` / `on_secondary_container` | ídem |
| `tertiary` | Acento terciario |
| `error` / `on_error` / `error_container` | Estados de error |

### Superficies (las más usadas en UI)

| Token | Uso |
|---|---|
| `background` | Fondo de página |
| `surface` | Fondo de componentes (= background en M3 schemes) |
| `surface_dim` | Surface más oscura |
| `surface_bright` | Surface más clara |
| `surface_container_lowest` | Contenedor más profundo |
| `surface_container_low` | Contenedor bajo |
| `surface_container` | Contenedor estándar |
| `surface_container_high` | Contenedor elevado |
| `surface_container_highest` | Contenedor más elevado |
| `on_surface` | Texto sobre surface |
| `on_surface_variant` | Texto secundario sobre surface |
| `outline` | Bordes visibles |
| `outline_variant` | Bordes sutiles |
| `inverse_surface` / `inverse_on_surface` | Para snackbars/tooltips invertidos |
| `scrim` / `shadow` | Overlays y sombras |

`colors.json` no incluye colores de terminal tipo `term0`-`term15` — el pipeline actual no los genera ni los necesita (Kitty se themea vía template + socket propio, no ANSI escapes a `/dev/pts`).

---

## 2. Pipeline implementado (estado real)

### Arquitectura

```
Notch shell (launcher wallpaper / theme views)
    ↓
notch shell/services/Theme.qml (matugen job)
    ↓ matugen image <wallpaper> --type <mode> --mode dark/light --prefer saturation --quiet
    ↓
~/.config/matugen/config.toml — 8 templates activos procesados en paralelo:
    ├── colors.json.template      → ~/.config/matugen/colors.json          (Quickshell)
    ├── kitty-theme.conf          → ~/.config/kitty/matugen-theme.conf
    ├── btop.theme                → ~/.config/btop/themes/matugen.theme
    ├── hypr-colors.lua           → ~/.config/hypr/deadlock/colors.lua
    ├── zen-matugen.css           → ~/.config/matugen/output/zen-matugen.css
    ├── zellij-theme.kdl          → ~/.config/zellij/themes/matugen.kdl
    ├── userContent.css           → ~/.config/matugen/output/userContent.css
    └── obsidian-theme.css        → ~/.config/matugen/output/obsidian-theme.css
    (gtk3/gtk4 templates comentados — GTK theming desactivado, ver CLAUDE.md)
    ↓
Theme.qml, after matugen exits 0
    ↓
~/.config/matugen/post-hook.sh
    ├── kitten @ set-colors --all ~/.config/kitty/matugen-theme.conf  (live, via socket)
    ├── killall -USR2 btop                                              (live)
    ├── hyprctl reload                                                  (live, recarga colors.lua)
    ├── cp zen-matugen.css → ~/.config/zen/<active-profile>/chrome/    (próximo inicio browser)
    │   + crea userChrome.css si no existe
    ├── gsettings set org.gnome.desktop.interface color-scheme — GTK/Electron/Zen (light/dark)
    ├── LibreOffice — patch estático de registrymodifications.xcu (con LO cerrado)
    └── Obsidian — copia obsidian-theme.css a cada vault (leídos dinámicamente de obsidian.json)

hyprpaper y el greeter SDDM no pasan por el post-hook: el propio notch escribe
~/.local/state/quickshell-notch/hyprpaper.conf y publica wallpaper + paleta al
greeter notch-lock en /var/lib/quickshell-notch-sddm/ (grupo sddm, 2750; ver
system/sddm/README.md). Sin helper root ni sudoers.
```

### Gotcha crítico: `run_hook` no funciona en matugen 4.1.0

El campo `run_hook` en `[config]` de `config.toml` parsea sin error pero **nunca ejecuta el script**. La solución es llamar el post-hook desde QML: `matugenProc.onExited: exitCode => { if (exitCode === 0) postHookProc.running = true }`.

### Detección del perfil activo de Zen

El archivo `profiles.ini` tiene dos mecanismos. La sección `[Install...]` es la autoritativa (la que Zen usa realmente). Las secciones `[ProfileN]` con `Default=1` son un fallback. El post-hook usa python3 para parsear ambas en orden:

```python
for s in p.sections():
    if s.startswith('Install'):
        path = p.get(s, 'Default', fallback=None)  # ← autoritativa
        if path: print(expanduser('~/.config/zen/' + path)); exit()
```

### Hyprland: `colors.lua` como módulo Lua

`~/.config/hypr/deadlock/colors.lua` retorna una tabla con hex_stripped (sin `#`). `decorations.lua` y `general.lua` hacen `local colors = require("deadlock.colors")` y construyen los valores de color con concatenación: `"rgba(" .. colors.primary .. "e6)"`. El archivo de fallback (Catppuccin Mocha) vive en `dotfiles/hypr/`.

### Gotcha: usar python3 en lugar de jq para leer colors.json

`jq` no está instalado en el PATH del hook. El post-hook usa
`python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d['colors']['primary']['hex'])"`.
`jq` sí está en `bootstrap.sh` (paso de CLI tools) para otros usos del sistema, pero python3 sigue siendo la dependencia usada acá — ya viene de base en Arch.

### Apps cubiertas y cuándo toman efecto

| App | Cuando toma efecto | Mecanismo |
|---|---|---|
| Quickshell | Inmediato | FileView onFileChanged → reload |
| Kitty | Inmediato | kitten @ set-colors en todas las ventanas abiertas |
| btop | Inmediato | SIGUSR2 |
| Hyprland borders/shadow | Inmediato | hyprctl reload (recarga colors.lua) |
| GTK/Electron/Zen color-scheme | Inmediato (apps ya abiertas pueden necesitar reload propio) | gsettings |
| LibreOffice | Próximo inicio (con LO cerrado) | patch de registrymodifications.xcu |
| Obsidian | Próximo inicio del vault (tema "Quickshell" debe estar seleccionado a mano una vez) | CSS copiado por vault |
| Zen Browser (Stylus vars) | ~1s (Chromium) / próximo inicio (Zen nativo) | ver `post-install.md` |
| Zellij | Próxima sesión nueva | KDL en themes/ auto-descubierto |
| hyprpaper | Inmediato | el notch reescribe su hyprpaper.conf |
| SDDM (notch-lock) | Próximo login | el notch publica wallpaper + paleta a /var/lib/quickshell-notch-sddm |
| fastfetch / ncmpcpp | Automático — usan nombres ANSI que kitty ya remapeó |

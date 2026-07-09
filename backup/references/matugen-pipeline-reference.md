# Pipeline de Colores — Referencia

Documentado desde la instalación viva de Caelestia.
Objetivo: entender el pipeline completo para replicarlo con matugen + Quickshell propio.

---

## Panorama general

```
Wallpaper cambia
    ↓
Generador de colores (Caelestia usa propio / nosotros usaremos matugen)
    ↓
scheme.json / colors.json  ← single source of truth
    ↓ (en paralelo)
┌─────────────────────────────────────────────────────┐
│  Quickshell       FileView watches → M3Palette live │
│  Hyprland         current.conf ($primary = hex)     │
│  Terminales       ANSI escape sequences a /dev/pts  │
│  Apps             templates renderizados            │
│  postHook         script con env vars de colores    │
└─────────────────────────────────────────────────────┘
```

---

## 1. Generación de colores

### Caelestia (sistema actual)

Caelestia tiene su propio generador. Para modo `dynamic` (wallpaper-based) usa el
algoritmo de Material You internamente. El resultado siempre es `scheme.json`.

```bash
caelestia scheme set dynamic       # genera desde wallpaper actual
caelestia scheme set catppuccin    # usa paleta predefinida
caelestia wallpaper -f /path/img   # cambia wallpaper + regenera si es dynamic
```

### matugen (lo que usaremos nosotros)

```bash
matugen image /path/to/wallpaper.jpg            # dark (default)
matugen image /path/to/wallpaper.jpg -m light   # light
matugen image /path/to/wallpaper.jpg -t fidelity # variante: fidelity/tonal_spot/etc
```

Genera `~/.config/matugen/colors.json` (ruta configurable).

---

## 2. Formato de los archivos de colores

### `scheme.json` (Caelestia) — `~/.local/state/caelestia/scheme.json`

```json
{
  "name": "shadotheme",
  "flavour": "default",
  "mode": "dark",
  "variant": "tonalspot",
  "colours": {
    "primary":              "bfc1ff",
    "onPrimary":            "282b60",
    "primaryContainer":     "6f72ac",
    "secondary":            "c5c4e0",
    "surface":              "131317",
    "surfaceContainer":     "1f1f23",
    "surfaceContainerHigh": "2a292e",
    "onSurface":            "e5e1e7",
    "onSurfaceVariant":     "c7c5d1",
    "outlineVariant":       "46464f",
    "error":                "ffb4ab",
    "term0": "353434",   "term8":  "ac9fa9",
    "term1": "a875ff",   "term9":  "bd95ff",
    ...
    "term15": "ffffff"
  }
}
```

**Importante:** los hex NO tienen `#`.

### `colors.json` (matugen) — `~/.config/matugen/colors.json`

```json
{
  "colors": {
    "primary":          { "hex": "#c2c1ff", "hex_stripped": "c2c1ff", "rgb": "rgb(194, 193, 255)", "rgba": "rgba(194, 193, 255, 255)" },
    "on_primary":       { "hex": "#2a2a60", ... },
    "surface":          { "hex": "#131317", ... },
    "surface_container":{ "hex": "#1f1f23", ... },
    ...
  },
  "scheme": "dark"
}
```

**Diferencias clave vs scheme.json:**

| | Caelestia scheme.json | matugen colors.json |
|---|---|---|
| Prefijo hex | Sin `#` (ej. `bfc1ff`) | Con `#` (ej. `#c2c1ff`) |
| Nombres de token | camelCase (`surfaceContainer`) | snake_case (`surface_container`) |
| Acceso | `colours.primary` | `colors.primary.hex` |
| Terminal colors | `term0`…`term15` incluídos | No incluídos — generar en postHook |
| Extras (catppuccin-style) | Sí (`mantle`, `crust`, `lavender`, etc.) | No |

---

## 3. Tokens disponibles (Material You completo)

Estos tokens existen en ambos sistemas (nombres en camelCase Caelestia / snake_case matugen):

### Colores base M3

| Token | Uso |
|---|---|
| `primary` | Acción principal, bordes activos |
| `onPrimary` | Texto sobre primary |
| `primaryContainer` | Contenedor de primary (más oscuro) |
| `onPrimaryContainer` | Texto sobre primaryContainer |
| `secondary` | Acción secundaria |
| `onSecondary` / `secondaryContainer` / `onSecondaryContainer` | ídem |
| `tertiary` | Acento terciario |
| `error` / `onError` / `errorContainer` | Estados de error |

### Superficies (las más usadas en UI)

| Token | Uso |
|---|---|
| `background` | Fondo de página |
| `surface` | Fondo de componentes (= background en M3 schemes) |
| `surfaceDim` | Surface más oscura |
| `surfaceBright` | Surface más clara |
| `surfaceContainerLowest` | Contenedor más profundo |
| `surfaceContainerLow` | Contenedor bajo |
| `surfaceContainer` | Contenedor estándar |
| `surfaceContainerHigh` | Contenedor elevado |
| `surfaceContainerHighest` | Contenedor más elevado |
| `onSurface` | Texto sobre surface |
| `onSurfaceVariant` | Texto secundario sobre surface |
| `outline` | Bordes visibles |
| `outlineVariant` | Bordes sutiles |
| `inverseSurface` / `inverseOnSurface` | Para snackbars/tooltips invertidos |
| `scrim` / `shadow` | Overlays y sombras |

### Terminales (solo Caelestia, generados por nosotros en postHook)

`term0`–`term7` → colores normales ANSI  
`term8`–`term15` → colores bright ANSI

---

## 4. Formato de templates

### Template simple (reemplaza literalmente)

Caelestia usa `{{ $colorName }}` → resultado sin `#`:

```ini
# btop.theme
theme[main_bg]={{ $surface }}
theme[hi_fg]={{ $primary }}
```

Output: `theme[main_bg]=131317`

Para dotfiles propios con matugen, el equivalente es `{{colors.surface.hex_stripped}}`.

### Template dinámico (con formas)

Caelestia usa `{{ colorName.form }}` para acceder a representaciones distintas:

```json
// zed.json (template)
"background": "#{{ surface.hex }}",
"foreground": "{{ onSurface.rgb }}",
```

Formas disponibles en Caelestia:
| forma | resultado |
|---|---|
| `.hex` | `131317` (sin #) |
| `.hexalpha` | `131317ff` (con alpha) |
| `.rgb` | `rgb(19,19,23)` |
| `.rgbalpha` | `rgba(19,19,23,255)` |

Con matugen el equivalente es `{{colors.surface.hex}}` (incluye #) o `{{colors.surface.hex_stripped}}` (sin #).

### Template con modo

```ini
# spicetify
[Caelestia]
text={{ $onSurface }}
# mode disponible como {{ $mode }} en Caelestia
```

En matugen: `{{scheme}}` → `"dark"` o `"light"`.

---

## 5. User templates de Caelestia

Los templates de usuario van en `~/.config/caelestia/templates/`.
Se procesan automáticamente en cada cambio de scheme.
Output va a `~/.local/state/caelestia/theme/<nombre-del-archivo>`.

```
~/.config/caelestia/templates/kitty-theme.conf
    ↓ caelestia scheme set ...
~/.local/state/caelestia/theme/kitty-theme.conf
```

Así es como Caelestia genera el kitty-theme.conf que después el script recarga con `kitten @`.

**Equivalente en dotfiles propios con matugen:**

```toml
# ~/.config/matugen/config.toml
[config]
reload_apps = true   # opcional: recarga apps automáticamente

[[templates]]
input_path = "~/.config/matugen/templates/kitty-theme.conf"
output_path = "~/.local/state/theme/kitty-theme.conf"

[[templates]]
input_path = "~/.config/matugen/templates/hypr-colors.conf"
output_path = "~/.config/hypr/scheme/current.conf"
```

---

## 6. Aplicación a cada destino

### Hyprland — `current.conf`

Caelestia genera `~/.config/hypr/scheme/current.conf` con formato:
```conf
$primary = bfc1ff
$onPrimary = 282b60
$surface = 131317
...
```
Hyprland lo sourcea en `hyprland.conf`. Luego `variables.conf` usa:
```conf
$activeWindowBorderColour = rgba($primarye6)   # color + alpha inline
$shadowColour = rgba($surfaced4)
```

Para replicar con matugen: template que genere este mismo formato `$nombre = hex`.

### Terminales — ANSI escape sequences

Caelestia escribe en `/dev/pts/*` sin requerir reinicio del terminal:

```python
# El formato es: \x1b]{code};rgb:{rr}/{gg}/{bb}\x1b\\
# Códigos:
# 10 = foreground (onSurface)
# 11 = background (surface)
# 12 = cursor (secondary)
# 4;0-7  = colores normales ANSI (term0-term7)
# 4;8-15 = colores bright ANSI (term8-term15)
```

En el postHook podemos replicar esto con un script bash:

```bash
hex_to_ansi() {
    local hex="$1"; shift
    for code in "$@"; do
        printf '\033]%s;rgb:%s/%s/%s\033\\' "$code" "${hex:0:2}" "${hex:2:2}" "${hex:4:2}"
    done
}
# Aplicar a todos los terminales abiertos:
for pt in /dev/pts/[0-9]*; do
    hex_to_ansi "$SURFACE"  11 > "$pt" 2>/dev/null || true
    hex_to_ansi "$ON_SURFACE" 10 > "$pt" 2>/dev/null || true
done
```

### Kitty — live reload via sockets

```bash
THEME="$HOME/.local/state/theme/kitty-theme.conf"
for sock in /tmp/kitty-*; do
    [[ "$sock" =~ ^/tmp/kitty-[0-9]+$ ]] || continue
    kitten @ --to "unix:$sock" set-colors --all "$THEME" 2>/dev/null
done
```

### btop — SIGUSR2

```bash
cp "$GENERATED_BTOP_THEME" "$HOME/.config/btop/themes/my-theme.theme"
killall -USR2 btop 2>/dev/null || true
```

### Zen Browser (y cualquier browser)

Copiar CSS con variables al directorio `chrome/` del perfil:
```bash
cp "$HOME/.local/state/theme/zen-colors.css" \
   "$HOME/.config/zen/<profile>/chrome/zen-colors.css"
```

Template `zen-colors.css`:
```css
:root {
    --c-accent:   #{{colors.primary.hex_stripped}};
    --c-surface:  #{{colors.surface.hex_stripped}};
    --c-on-surface: #{{colors.on_surface.hex_stripped}};
}
```

---

## 7. postHook

### En Caelestia

```json
// ~/.config/caelestia/cli.json
{
  "theme": {
    "postHook": "~/.config/caelestia/scripts/my-hook.sh"
  }
}
```

Variables de entorno disponibles en el script:
```
SCHEME_NAME      = "dynamic"
SCHEME_FLAVOUR   = "default"
SCHEME_MODE      = "dark"
SCHEME_VARIANT   = "tonalspot"
SCHEME_COLOURS   = '{"primary":"bfc1ff","surface":"131317",...}'  ← JSON completo
```

### Con matugen

matugen no tiene postHook nativo, pero el script de cambio de wallpaper puede encadenarlo:

```bash
#!/usr/bin/env bash
# wallpaper-change.sh — script maestro
WALLPAPER="$1"

# 1. Cambiar wallpaper
swww img "$WALLPAPER" --transition-type fade

# 2. Generar colores
matugen image "$WALLPAPER"

# 3. Aplicar templates (matugen lo hace si reload_apps=true en config.toml)
# o manualmente:
# matugen image "$WALLPAPER" -t fidelity

# 4. Ejecutar postHook propio
~/.config/matugen/post-hook.sh "$WALLPAPER"
```

---

## 8. Quickshell — cómo consume los colores

Ver `references/caelestia/caelestia-shell-architecture.md` para el detalle completo.
Resumen del patrón que hay que replicar:

```qml
// services/Colours.qml
pragma Singleton

QtObject {
    // FileView vigila el JSON en disco
    readonly property FileView schemeFile: FileView {
        path: `${Paths.state}/caelestia/scheme.json`  // o matugen/colors.json
        watchChanges: true
        onTextChanged: root.load(JSON.parse(text()))
    }

    // Propiedades bindeadas desde el JSON
    property color primary: "transparent"
    property color surface: "transparent"
    property color onSurface: "transparent"
    // ...

    function load(data) {
        // Caelestia: data.colours.primary → sin #, hay que agregar
        primary = "#" + data.colours.primary
        // matugen: data.colors.primary.hex → ya tiene #
        // primary = data.colors.primary.hex
    }
}
```

**Gotcha importante:** Caelestia scheme.json tiene hex SIN `#`. Si leés el JSON en QML
y lo asignás a un `color`, hay que agregarlo: `"#" + data.colours.primary`.

Con matugen colors.json podés usar `data.colors.primary.hex` directamente (incluye `#`).

---

## 9. Decisión para dotfiles propios

**Recomendación:** usar el formato de matugen nativo (`colors.json`) en Quickshell,
NO convertir a scheme.json. Simplifica el pipeline.

```
matugen image $WALLPAPER
    → ~/.config/matugen/colors.json
         → FileView en Quickshell (lee colors.json)
         → templates/ (kitty, hypr, zen, btop)
         → post-hook.sh (terminales, kitty sockets, notifs)
```

El único trabajo extra: generar los `term0`-`term15` en el postHook,
ya que matugen no los incluye. Se pueden derivar de la paleta M3 con un script.

---

## 10. Checklist de integración por app

| App | Mecanismo | Template necesario |
|---|---|---|
| Hyprland borders | `current.conf` sourced en `hyprland.conf` | `hypr-colors.conf` → `$var = hex` |
| Kitty | `kitten @ set-colors` via socket | `kitty-theme.conf` con tokens M3 |
| Terminales (pt) | ANSI escapes a `/dev/pts/*` | No template, script directo |
| btop | Copiar `.theme` + `SIGUSR2` | `btop.theme` con `{{ hex }}` |
| Zen Browser | Copiar CSS a chrome/ | `zen-colors.css` con CSS vars |
| Obsidian | Copiar CSS a cada vault/.obsidian/themes/ | `obsidian-theme.css` |
| Spicetify | `color.ini` en Themes/caelestia/ | `spicetify.ini` |
| GTK 3/4 | `gtk.css` + dconf icon theme | `gtk.css` con @define-color |
| QT | qtengine colors file | `qt.colors` |
| Quickshell | FileView en Colours.qml | No template — lee JSON directo |

---

## 11. Pipeline implementado (estado actual — 2026-07-07)

### Arquitectura real

```
Quickshell (launcher >wallpaper / >theme)
    ↓
Colours.qml._runMatugen()
    ↓ matugen image <wallpaper> --type <mode> --mode dark/light --prefer saturation --quiet
    ↓
~/.config/matugen/config.toml — 6 templates procesados en paralelo:
    ├── colors.json.template      → ~/.config/matugen/colors.json          (Quickshell)
    ├── kitty-theme.conf          → ~/.config/kitty/matugen-theme.conf
    ├── btop.theme                → ~/.config/btop/themes/matugen.theme
    ├── hypr-colors.lua           → ~/.config/hypr/deadlock/colors.lua
    ├── zen-matugen.css           → ~/.config/matugen/output/zen-matugen.css
    └── zellij-theme.kdl          → ~/.config/zellij/themes/matugen.kdl
    ↓
Colours.qml.matugenProc.onExited (exitCode === 0)
    ↓
~/.config/matugen/post-hook.sh
    ├── kitten @ set-colors --all ~/.config/kitty/matugen-theme.conf  (live, via socket)
    ├── killall -USR2 btop                                              (live)
    ├── hyprctl reload                                                  (live, recarga colors.lua)
    ├── cp zen-matugen.css → ~/.config/zen/<active-profile>/chrome/    (próximo inicio browser)
    │   + crea userChrome.css si no existe
    ├── hyprpaper — reescribe ~/.config/hypr/hyprpaper.conf con path actual
    │   Si wallpaper es video: extrae primer frame con ffmpeg a
    │   ~/.local/state/quickshell/hyprpaper-frame.jpg (full quality, -q:v 2)
    │   Reinicia proceso: pkill hyprpaper && sleep 0.3 && hyprpaper &
    └── SDDM silent theme — genera configs/custom.conf con colores matugen
        Copia wallpaper a backgrounds/qs-current.<ext> via
        sudo /usr/local/bin/sddm-theme-sync (NOPASSWD, /etc/sudoers.d/sddm-theme-sync)
        Lee primary/on_primary de colors.json con python3 (no jq — ver gotcha abajo)
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

`jq` no está instalado en este sistema (no está en el PATH del hook). El post-hook usa
`python3 -c "import json; d=json.load(open('$COLORS_JSON')); print(d['colors']['primary']['hex'])"`.
Cuando se instale `jq` (bootstrap.sh lo incluye en el paso de CLI tools) se puede simplificar,
pero python3 ya está disponible en Arch de base y es la dependencia más segura.

### Apps cubiertas y cuándo toman efecto

| App | Cuando toma efecto | Mecanismo |
|---|---|---|
| Quickshell | Inmediato | FileView onFileChanged → reload |
| Kitty | Inmediato | kitten @ set-colors en todas las ventanas abiertas |
| btop | Inmediato | SIGUSR2 |
| Hyprland borders/shadow | Inmediato | hyprctl reload (recarga colors.lua) |
| Zen Browser | Próximo inicio del browser | CSS copiado a chrome/ |
| Zellij | Próxima sesión nueva | KDL en themes/ auto-descubierto |
| hyprpaper | Inmediato | reescribe hyprpaper.conf + reinicia proceso |
| SDDM | Próximo login | copia wallpaper + genera custom.conf vía helper sudo |

### Helper privilegiado SDDM

`/usr/local/bin/sddm-theme-sync` — script root-owned instalado por `bootstrap.sh`.
- Valida: wallpaper existe, dest_name es `qs-current.<ext>` (previene path traversal), conf existe
- Borra `qs-current.*` anterior, copia nuevo wallpaper, sobreescribe `configs/custom.conf`
- Sudoers: `/etc/sudoers.d/sddm-theme-sync` — `deadlock ALL=(root) NOPASSWD: /usr/local/bin/sddm-theme-sync`
- Fuente en dotfiles: `dotfiles/matugen/.config/matugen/sddm-theme-sync`
| fastfetch / ncmpcpp | Automático — usan nombres ANSI que kitty ya remapeó |

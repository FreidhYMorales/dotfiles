# Caelestia Shell — Arquitectura

Shell upstream explorado desde `/etc/xdg/quickshell/caelestia/`.
Stack: Arch Linux + Hyprland + Quickshell (Qt6/QML) + matugen.

---

## Estructura de directorios

```
/etc/xdg/quickshell/caelestia/
├── shell.qml                   ← Entry point (ShellRoot)
├── assets/                     ← GIFs, PNG, SVG, shaders GLSL (.frag + .qsb), PAM config
├── components/                 ← UI primitives reutilizables
│   ├── Anim.qml                ← NumberAnimation con type system M3
│   ├── AnchorAnim.qml          ← AnchorAnimation con type system M3
│   ├── CAnim.qml               ← ColorAnimation (shorthand)
│   ├── StyledRect.qml          ← Rectangle con Behavior on color { CAnim {} } built-in
│   ├── StyledText.qml          ← Text con animate support
│   ├── StateLayer.qml          ← Ripple + hover state overlay (Material 3)
│   ├── MaterialIcon.qml        ← Variable-font icon renderer
│   ├── misc/CustomShortcut.qml ← Wrapper de Quickshell shortcut para Hyprland global binds
│   ├── containers/             ← StyledWindow (PanelWindow base), Flickable, ListView
│   ├── controls/               ← Slider, Switch, Button, InputField, Menu, Tooltip, etc.
│   └── effects/                ← ColouredIcon, Colouriser, Elevation, InnerBorder, OpacityMask
├── modules/                    ← Módulos UI top-level
│   ├── background/             ← Wallpaper + Visualiser (cava) + DesktopClock
│   ├── bar/                    ← Bar, BarWrapper, componentes de bar, popouts
│   ├── drawers/                ← Layout completo de la shell (el sistema de drawers)
│   ├── dashboard/              ← Panel superior: media, clima, recursos, calendario
│   ├── launcher/               ← App launcher + acciones + wallpapers
│   ├── lock/                   ← Lock screen (WlSessionLock + PAM + fingerprint)
│   ├── notifications/          ← Toast notifications
│   ├── osd/                    ← On-screen display (volumen, brillo)
│   ├── session/                ← Panel de sesión (power off, reboot, etc.)
│   ├── sidebar/                ← Panel derecho de notificaciones
│   ├── utilities/              ← Panel inferior derecho (toggles, recording, toasts)
│   ├── controlcenter/          ← Ventana flotante de settings
│   └── Shortcuts.qml           ← Todos los IpcHandlers + CustomShortcuts
├── services/                   ← Singletons globales (pragma Singleton)
│   ├── Colours.qml             ← Paleta M3 + capa de transparencia
│   ├── Hypr.qml                ← Bridge Hyprland (toplevels, workspaces, monitors, IPC)
│   ├── Audio.qml               ← PipeWire + Cava + BeatTracker
│   ├── Brightness.qml          ← brightnessctl / ddcutil / asdbctl por monitor
│   ├── Notifs.qml              ← NotificationServer + persistencia JSON
│   ├── Players.qml             ← MPRIS via Quickshell.Services.Mpris
│   ├── Network.qml             ← nmcli facade + NetworkUsage
│   ├── SystemUsage.qml         ← /proc/stat, /proc/meminfo, sensors, nvidia-smi
│   ├── Wallpapers.qml          ← FileSystemModel + FileView (watch path.txt)
│   ├── Screens.qml             ← Quickshell.screens filtrado por config
│   ├── Time.qml                ← SystemClock singleton
│   ├── Visibilities.qml        ← Map<HyprlandMonitor, DrawerVisibilities>
│   ├── GameMode.qml            ← PersistentProperties; desactiva anim/blur/gaps en Hypr
│   ├── Recorder.qml            ← gpu-screen-recorder process wrapper
│   └── LyricsService.qml       ← .lrc locales + NetEase Music API fallback
└── utils/
    ├── Icons.qml               ← Icon lookup helpers (weather, network, BT, battery)
    ├── Paths.qml               ← XDG path singletons (data/state/cache/config/walls)
    ├── Searcher.qml            ← Fuzzy/exact search sobre lista
    └── scripts/                ← fuzzysort.js, fzf.js, lrcparser.js
```

---

## Entry point: `shell.qml`

```qml
ShellRoot {
    settings.watchFiles: false   // no hot-reload en producción

    Background {}     // por pantalla: wallpaper + visualiser
    Drawers {}        // toda la shell (bar + todos los paneles)
    AreaPicker {}     // selector de región para screenshots
    Lock { id: lock }
    ConfigToasts {}
    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors { lock: lock }
}
```

Pragmas al inicio del archivo:
```qml
// @pragma QS_NO_RELOAD_POPUP=1
// @pragma QS_DROP_EXPENSIVE_FONTS=1
// @pragma QSG_RENDER_LOOP=threaded
// @pragma QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
```

---

## Flujo de colores: matugen → QML

```
caelestia scheme set <name>
  └─ escribe ~/.local/state/caelestia/scheme.json
  └─ escribe ~/.config/hypr/scheme/current.conf  ($primary = hex, etc.)

Colours.qml (singleton)
  ├── FileView { path: "${Paths.state}/scheme.json"; watchChanges: true }
  │     └── onTextChanged → load(text(), false)
  │           └── parsea JSON → setea M3Palette props (m3primary, m3surface, etc.)
  ├── M3Palette  ← raw hex, para texto e iconos
  └── M3TPalette ← con transparencia aplicada, para fondos
        └── root.layer(color, layerIndex)
              ├── Layer 0 (fondos): Qt.alpha(c, transparency.base)
              └── Layer 1+ (surfaces): alterColour() → ajusta luminance + aplica alpha
                    └── wallLuminance viene de ImageAnalyser en Wallpapers.current

Componentes:
  color: Colours.tPalette.m3surfaceContainer  ← fondos (con transparencia)
  color: Colours.palette.m3primary            ← texto/iconos (sin transparencia)
```

---

## IPC: Hyprland ↔ Shell (5 canales)

### Canal 1: Quickshell built-in `Quickshell.Hyprland`

`Hypr.qml` envuelve el módulo QML nativo. Escucha `Hyprland.onRawEvent` y llama
`refreshWorkspaces()`, `refreshToplevels()`, `refreshMonitors()` para eventos específicos
(`workspace`, `openwindow`, `closewindow`, `configreloaded`, etc.).

### Canal 2: `IpcHandler { target: "..." }`

Callable desde terminal o Hyprland `exec` via `caelestia <target> <method> [args]`:

| target | métodos |
|---|---|
| `drawers` | `toggle(drawer)`, `list()` |
| `lock` | `lock()`, `unlock()`, `isLocked()` |
| `wallpaper` | `get()`, `set(path)`, `list()` |
| `audio` | `cycleOutput` |
| `brightness` | `get()`, `set(value)`, `getFor(query)`, `setFor(query, value)` |
| `notifs` | `clear()`, `toggleDnd()`, `enableDnd()`, `disableDnd()` |
| `mpris` | `play`, `pause`, `playPause`, `previous`, `next`, `stop` |
| `toaster` | `info`, `success`, `warn`, `error` |
| `gameMode` | `toggle()`, `enable()`, `disable()`, `isEnabled()` |
| `controlCenter` | `open()` |
| `hypr` | `refreshDevices`, `cycleSpecialWorkspace`, `listSpecialWorkspaces` |

### Canal 3: `CustomShortcut` + Hyprland `global` binds

```conf
# keybinds.conf
bind = Super, L, global, caelestia:lock
bindi = Super, Super_L, global, caelestia:launcher
```
```qml
// Lock.qml
CustomShortcut { name: "lock"; onReleased: root.lock() }
```

### Canal 4: `HyprExtras` (extended Hyprland commands)

```qml
Hypr.extras.batchMessage([...])        // múltiples keyword/dispatch en una llamada
Hypr.extras.applyOptions({...})        // GameMode: anula anim/blur/gaps sin reload
Hypr.extras.message("reload")          // hyprctl reload
Hypr.extras.devices.keyboards          // enumeración de dispositivos
```

### Canal 5: `FileView` watchChanges (shell ← disco)

```qml
// Wallpapers.qml
FileView { path: "${Paths.state}/wallpaper/path.txt"; watchChanges: true }
// CLI escribe el path, shell reacciona
```

---

## Arquitectura de Drawers (layout principal de la shell)

### Per-screen con `Variants`

```qml
// Drawers.qml
Variants {
    model: Screens.screens   // una instancia por pantalla
    // cada Scope contiene: Exclusions + ContentWindow
}
```

### `ContentWindow` — el canvas de la shell

`PanelWindow` (WlrLayershell) a pantalla completa + transparente:
- `namespace: "caelestia-drawers"` — para `layerrule` en Hyprland
- `ExclusionMode.Ignore` — el bar maneja su propia exclusive zone
- `WlrKeyboardFocus.OnDemand` — teclado solo cuando launcher/session lo necesita
- `HyprlandFocusGrab` — grab de foco para launcher/session/sidebar

**Renderizado visual:** usa `BlobGroup` / `BlobInvertedRect` / `BlobRect` con SDF (signed
distance field) para fondos orgánicos que conectan paneles. Los paneles se "bulge" desde
la superficie con `deformAmount` configurable. El contenido de cada panel recibe un
`Matrix4x4 { matrix: panelBg.deformMatrix }` para seguir la deformación SDF.

### `DrawerVisibilities` — estado por pantalla

```qml
// DrawerVisibilities.qml
PersistentProperties {
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar
}
```

`Visibilities.qml` mantiene `Map<HyprlandMonitor, DrawerVisibilities>`, permitiendo que
`Shortcuts.qml` haga `Visibilities.getForActive().launcher = true` solo en la pantalla activa.

### `Interactions.qml` — sistema de hover/drag

Un solo `CustomMouseArea` a pantalla completa rutea toda la interacción:
- **Bar:** hover en borde izquierdo, o drag derecho > umbral
- **Dashboard:** hover en strip superior, o drag hacia abajo > umbral
- **Launcher:** hover en strip inferior, o drag hacia arriba > umbral
- **Session:** drag desde borde derecho hacia izquierda
- **OSD:** hover en borde derecho dentro de banda de altura OSD
- **Utilities:** hover en esquina inferior derecha

`shortcutActive` flags por panel previenen que hover cierre paneles abiertos por teclado.

---

## Sistema de animaciones

Basado en Material Design 3 expressive motion tokens (`Tokens.anim.*`).

```qml
// Anim.qml — types disponibles:
// StandardSmall, Standard, StandardLarge
// EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge
// FastSpatial, DefaultSpatial, SlowSpatial

// Uso típico en estado+transición:
states: State {
    name: "visible"; when: root.shouldBeVisible
    PropertyChanges { root.implicitWidth: root.contentWidth }
}
transitions: [
    Transition { to: "visible"; Anim { type: Anim.DefaultSpatial } },
    Transition { from: "visible"; Anim { type: Anim.Emphasized } }
]

// Behavior shorthand:
Behavior on opacity { Anim {} }
Behavior on color   { CAnim {} }   // via StyledRect built-in
```

---

## Hyprland config upstream (`~/.local/share/caelestia/hypr/`)

```
hypr/
├── hyprland.conf          ← Master; sourcea todo
├── variables.conf         ← $variables (apps, keybinds, colores, gaps, blur)
├── scheme/
│   ├── default.conf       ← Paleta M3 fallback (~100 variables en hex)
│   └── current.conf       ← Scheme activo (symlink/copia de default o salida matugen)
├── scripts/
│   ├── configs.fish       ← Crea hypr-vars.conf y hypr-user.conf si no existen; reload
│   └── wsaction.fish      ← Workspace groups (grupo × 10 + offset)
└── hyprland/
    ├── animations.conf    ← 4 bezier + animaciones
    ├── decoration.conf    ← rounding, blur, shadow (usa $variables)
    ├── env.conf
    ├── execs.conf         ← gnome-keyring, polkit, cliphist, gammastep, mpris-proxy, caelestia
    ├── general.conf       ← layout=dwindle, gaps, border colors
    ├── gestures.conf      ← 4-finger swipe workspace, 3-finger special ws
    ├── input.conf
    ├── keybinds.conf      ← submap global + caelestia:* global shortcuts
    ├── misc.conf          ← VRR, session lock, dpms
    └── rules.conf         ← windowrule + layerrule para capas caelestia
```

### Bootstrap sequence de `hyprland.conf`

1. Source `scheme/current.conf` → carga `$primary`, `$surface`, etc.
2. Source `variables.conf` → carga `$terminal`, `$browser`, keybind vars
3. Exec `configs.fish` → crea archivos de user si faltan, dispara `hyprctl reload`
4. Source todos los archivos modulares

### Colores en Hyprland

```conf
# variables.conf usa scheme colors directamente:
$activeWindowBorderColour   = rgba($primarye6)        # color + alpha inline
$inactiveWindowBorderColour = rgba($onSurfaceVariant11)
$shadowColour               = rgba($surfaced4)
# misc.conf:
background_color = rgb($surfaceContainer)
```

### Keybinds: patrón `launcher interrupt`

```conf
bindi = Super, Super_L, global, caelestia:launcher
bind  = Super, A, global, caelestia:launcherInterrupt
bind  = Super, B, global, caelestia:launcherInterrupt
# ... (todos los Super+key combos)
```

Si se presiona otro botón mientras Super está held, `launcherInterrupt` setea
`launcherInterrupted = true` en el shell → el launcher NO se abre al soltar Super.
Permite combos Super+key sin abrir el launcher.

---

## Flujo completo de datos (resumen)

```
matugen (CLI)
  → scheme.json         → Colours.FileView → M3Palette → bind en UI
  → current.conf        → hyprctl reload   → $primary en borders/shadows

caelestia wallpaper -f <path>
  → swww/hyprpaper (external)
  → wallpaper/path.txt  → Wallpapers.FileView → ImageAnalyser → wallLuminance
                                               → Colours.alterColour() se ajusta

Hyprland event (workspace change, window open/close)
  → Hypr.onRawEvent → refreshWorkspaces/refreshToplevels → bindings en UI

Hyprland keybind "global, caelestia:launcher"
  → CustomShortcut.onReleased
  → Visibilities.getForActive().launcher = !launcher
  → Panels.launcher visible = true
  → Anim transition DefaultSpatial
```

# Componentes, utils y scripts

---

## Componentes (`components/`)

### `CAnim.qml`

Animación de color estándar. Usar en **todos** los elementos con `color` property para soportar el hot-reload de paleta de matugen.

```qml
// Uso:
Behavior on color { CAnim {} }

// Equivalente a:
Behavior on color { ColorAnimation { duration: 200 } }
```

### `Anim.qml`

Animaciones de entrada/salida para transiciones de layout. Usado en `BgAppsWidget` para el expand al hover.

```qml
Behavior on implicitWidth { Anim { type: Anim.Enter } }
// type: Anim.Enter | Anim.Leave
```

### `StyledRect.qml`

Rectangle mínimo: solo agrega `Behavior on color { CAnim {} }` — no define `color` ni `radius` propios, esos siguen siendo los defaults/props normales de `Rectangle`. El valor está en no tener que escribir el `Behavior` a mano en cada uso.

### `StyledText.qml`

`Text` con la fuente y color del sistema de diseño ya seteados (`font.family: Style.fontFamily`, `color: Colours.m3onSurface`, `renderType: Text.NativeRendering`), más `Behavior on color { CAnim {} }` para el hot-reload de paleta.

```qml
property bool animate: false   // true → crossfade (fade out/in) al cambiar `text`, en vez de salto instantáneo
property var  fontStyle        // objeto de fuente (family/pixelSize/weight) aplicado sobre los defaults
```

### `StateLayer.qml`

`Rectangle` de overlay Material Design para hover/press (tinte semitransparente sobre el elemento que lo contiene) — encapsula el `MouseArea` interno para no repetirlo en cada botón.

```qml
property color tintColor:      "#ffffff"  // color del tinte (normalmente el color de texto/ícono del elemento)
property real  hoverOpacity:   0.08
property real  pressedOpacity: 0.12
property bool  hoverEnabled:   true
property int   cursorShape:    Qt.ArrowCursor
signal clicked()
```

`radius` sigue automáticamente el de `parent` (`radius: parent ? parent.radius : 0`, con guard `!== undefined` — si el padre es un `Item` liso sin `radius` propio, cae a `0` en vez de `undefined`).

### `Capsule.qml`

`Rectangle` con el estilo terminal-alike de las tarjetas del dashboard ya preconfigurado: `radius: Style.cornerRadius`, `border.width: 2`, `border.color: Qt.alpha(Colours.m3primary, 0.9)`, `Behavior on color { CAnim {} }`. `color` por defecto es `Colours.layer(Colours.m3surfaceContainer, 2)` — pisable (el panel de perfil usa `Colours.m3surfaceContainer` liso). Usado por las 5 cápsulas de `DashboardContent.qml` (panel de perfil, notificación, clima, batería+performance, música) — antes cada una repetía las mismas 4 líneas de estilo.

### `MonitorOsdWindow.qml`

Wrapper compartido para los OSD simples de la barra (`TrayMenuOsd`, `BatteryProfileOsd`, `RecorderModeOsd`) — un `PanelWindow` por pantalla (solo visible en la enfocada), paleta por monitor ya resuelta, capa/namespace/anchors estándar. Raíz es un `Item` (no `Variants` directo) porque `Variants` trata cualquier hijo declarado en su default property como parte de la expansión por modelo e intenta inyectarle `modelData` — rompía los `Timer`/`Connections` que cada OSD agrega encima.

```qml
MonitorOsdWindow {
    namespace:  "deadlock-algo"
    osdHeight:  60
    osdVisible: _visible   // cada OSD maneja su propio show/hide timer + Connections
    content: Component {
        Item {
            property PanelWindow win: null  // NO required property — ver nota abajo
            property var osd: null          // referencia al MonitorOsdWindow externo (funciones como pauseAutoClose())
            anchors.fill: parent
            // ... usa win.colors / win.isFocused / win.width sin calificar
        }
    }
}
```

`win`/`osd` se pasan como propiedades iniciales de `createObject(win.contentItem, { win: win, osd: root })` — **no** `Loader.onLoaded`, evita que los bindings del contenido evalúen una vez con `win = null` antes de que se asigne. Parentear a `win` directo (no `win.contentItem`) tira `"Created graphical object was not placed in the graphics scene"` — una `PanelWindow` no es un `Item` de la escena.

El show/hide timer + `Connections` a `Visibilities.*` quedan a propósito fuera de este componente — cada OSD los agrega como hijos extra del `MonitorOsdWindow` (funciona porque la raíz es `Item`, no `Variants`). `Osd.qml` (volumen/brillo) no usa este wrapper — tiene dos flujos de show/hide independientes y matemática de posicionamiento propia por pantalla, no encaja en el modelo de una sola bandera `osdVisible`.

### `qmldir`

Registra los tipos del módulo: `Anim`, `CAnim`, `Capsule`, `StyledRect`, `StyledText`, `StateLayer`, `MonitorOsdWindow`. Necesario para que QML los encuentre con `import "../../components"`.

---

## Subdirectorios de `components/`

Cada subdirectorio tiene su propio `qmldir` — se importan igual, por ruta relativa (`import "../../components/controls"`, etc.).

| Subdirectorio | Componentes |
|---|---|
| `controls/` | `IconButton`, `SegmentedMeter`, `Slider`, `Toggle` |

`containers/`, `effects/`, `images/`, `misc/` y `widgets/` existieron pero se borraron — cada uno tenía solo componentes sin ningún call site en el proyecto (código muerto, nunca conectado).

---

## Utils (`utils/`)

### `Paths.qml`

Resuelve rutas absolutas relativas a la configuración del shell.

```qml
import "../../utils"

// Uso:
Process { command: ["python3", Paths.scripts + "/list-apps.py"] }
```

**Propiedades:**
```qml
// XDG base dirs (con fallback si la env var no está seteada)
Paths.home     // $HOME
Paths.config   // $XDG_CONFIG_HOME || ~/.config
Paths.state    // $XDG_STATE_HOME  || ~/.local/state
Paths.cache    // $XDG_CACHE_HOME  || ~/.cache
Paths.data     // $XDG_DATA_HOME   || ~/.local/share

Paths.shell         // ~/.config/quickshell/deadlock
Paths.matugenColors // ~/.config/matugen/colors.json
Paths.scripts       // ruta a quickshell/scripts/ (resuelta con Qt.resolvedUrl, sin "file://")

// Caelestia-compatible
Paths.notifimagecache  // ~/.cache/caelestia/imagecache/notifs

// Lock module — assets porteados del theme SDDM "silent"
Paths.lockAssets           // quickshell/modules/lock/assets
Paths.lockConfigDir        // .../assets/configs
Paths.lockIconsDir         // .../assets/icons
Paths.lockBackgroundsDir   // .../assets/backgrounds
Paths.activeLockConfig     // $QS_LOCK_THEME || "custom"
Paths.lockVkeyboardStylesDir // .../assets/vkeyboard-styles — agregar a QML_IMPORT_PATH antes de lanzar `qs`, QML no puede setear esta env var en caliente

// Wallpaper picker + theming-mode picker
Paths.wallpapersDir              // $QS_WALLPAPER_DIR || ~/Pictures/Wallpaper
Paths.appState                   // ~/.local/state/quickshell
Paths.wallpaperStatePath         // .../wallpaper.txt
Paths.wallpaperPerScreenStatePath // .../wallpaper-screens.json
Paths.themeStatePath             // .../theme.json
Paths.idleStatePath              // .../idle.json
Paths.weatherLocPath             // .../weather-loc.json

// Screen recording (services/Recorder.qml) — solo carpeta de salida, sin archivo de persistencia
Paths.recordingsDir  // $QS_RECORDINGS_DIR || ~/Videos/Recordings

Paths.absolutePath(path)  // resuelve ~ y $HOME/${HOME} al inicio de un path
```

### `Icons.qml`

Singleton — mapeo de íconos, API compatible con Caelestia. No resuelve rutas de archivo: devuelve nombres de ícono Material Symbols (strings) que otro componente decide cómo pintar.

```qml
import "../../utils"

Icons.getWeatherIcon(code)            // código WMO (Open-Meteo) → nombre de ícono ("clear_day", "rainy", "thunderstorm"...), fallback "air"
Icons.getNotifIcon(summary, urgency)  // heurística por palabras clave en el summary ("reboot", "battery", "update"...), fallback por NotificationUrgency.Critical → "release_alert", si no "chat"
Icons.getVolumeIcon(volume, isMuted)  // volume es 0..1 (no 0..100) — "no_sound" / "volume_up" / "volume_down" / "volume_mute"
Icons.getBatteryIcon(percentage, charging)  // percentage es 0..1 — devuelve nombres tipo "battery_charging_80"/"battery_3_bar"
```

⚠️ `getVolumeIcon`/`getBatteryIcon` esperan fracciones (`0..1`), no porcentajes enteros — distinto de cómo el resto del proyecto maneja volumen/batería (`Audio.volume`/`Battery.percentage` en 0..100). Revisar el call site antes de reusar.

### `CUtils.qml`

Singleton — funciones utilitarias genéricas, API compatible con Caelestia.

```qml
import "../../utils"

CUtils.clamp(value, min, max)     // Math.max(min, Math.min(max, value))
CUtils.lerp(a, b, t)              // interpolación lineal
CUtils.formatDuration(seconds)    // "m:ss" (sin padding en minutos, sí en segundos)
CUtils.toLocalFile(url)           // strips "file://" — para pasar QUrl-like strings a Process/comandos externos
```

### `SysInfo.qml` (`utils/`)

⚠️ No confundir con `services/SysInfo.qml` — este vive en `utils/` y expone **propiedades string** para mostrar (nombre de OS, kernel, uptime formateado), no los porcentajes numéricos de CPU/RAM/GPU/Disk (eso lo tiene el singleton de `services/`).

```qml
import "../../utils"

SysInfo.osName          // "Arch Linux" (fallback si falta /etc/os-release)
SysInfo.osPrettyName    // PRETTY_NAME de /etc/os-release
SysInfo.osId            // ID de /etc/os-release ("arch")
SysInfo.osLogo          // ruta resuelta vía Quickshell.iconPath(), o "" si no hay LOGO en os-release
SysInfo.isDefaultLogo   // true mientras no se resolvió un logo real — para decidir un ícono de respaldo
SysInfo.wm              // XDG_CURRENT_DESKTOP env var, fallback "Hyprland"
SysInfo.user            // USER env var (readonly)
SysInfo.uptime          // "1d 2h 30m" — formateado, se refresca cada 30s
SysInfo.kernel          // /proc/sys/kernel/osrelease
SysInfo.hostname        // /proc/sys/kernel/hostname
```

Lee `/etc/os-release`, `/proc/sys/kernel/osrelease` y `/proc/sys/kernel/hostname` una vez vía `FileView`; `uptime` se recalcula cada 30s con un `Timer` que llama `uptimeFile.reload()`.

---

## Scripts (`scripts/`)

### `list-apps.py`

Parsea archivos `.desktop` para el launcher. Corre como proceso externo desde `LauncherContent`.

**Búsqueda de archivos:**
1. `/usr/share/applications/*.desktop`
2. `~/.local/share/applications/*.desktop`

**Filtros:**
- Excluye entradas con `NoDisplay=true` o `Hidden=true`
- Excluye entradas sin campo `Exec`
- Deduplicación por nombre

**Limpieza de `Exec`:**
Elimina placeholders de freedesktop: `%U`, `%u`, `%F`, `%f`, `%i`, `%c`, `%k`, `%d`, `%D`, `%n`, `%N`, `%v`, `%m`.

**Output:** JSON array por stdout:
```json
[
  {
    "name": "Firefox",
    "exec": "firefox",
    "icon": "/usr/share/icons/hicolor/48x48/apps/firefox.png",
    "description": "Web Browser"
  }
]
```

⚠️ El ícono puede ser una ruta absoluta o un nombre de tema (`"firefox"`). `AppItem` usa `Image { source: appIcon }` — QML resuelve nombres de tema automáticamente en Qt6.

---

## Convenciones de nombres en QML

| Patrón | Significado |
|---|---|
| `_expanded`, `_syncPos()` | Prefijo `_` = privado/interno al componente |
| `Colours.m3*` | Token Material 3 de la paleta |
| `CAnim {}` | Animación de color estándar |
| `HoverHandler { id: hov }` | Handler de hover reutilizable |
| `hov.hovered` | Estado de hover — **solo con `HoverHandler`** (`QQuickHoverHandler`). `HoverHandler` NO tiene `containsMouse`: esa property no existe en el tipo, así que la expresión evalúa a `undefined` (siempre falso) sin tirar ningún error — bug real ya encontrado y corregido en varios componentes del proyecto. |
| `ma.containsMouse` (con `MouseArea { id: ma }`) | Estado de hover — **solo con `MouseArea`**, que sí expone `containsMouse` (requiere `hoverEnabled: true`). Nunca mezclar los dos nombres entre los dos tipos de handler. |
| `Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }` | Expand/collapse estándar |

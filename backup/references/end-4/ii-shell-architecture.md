# ii (illogical-impulse) — Shell Architecture

Shell explorado desde `~/.cache/dots-hyprland/dots/.config/quickshell/ii/`.
Stack: Arch Linux + Hyprland + Quickshell (Qt6/QML) + matugen.

Ver también: [`ii-quickshell-patterns.md`](ii-quickshell-patterns.md) para patterns concretos.

---

## Estructura de directorios

```
~/.config/quickshell/ii/
├── shell.qml                   ← Entry point (ShellRoot)
├── GlobalStates.qml            ← Boolean switchboard global de todos los paneles
├── ReloadPopup.qml             ← Popup de recarga de Quickshell
├── killDialog.qml              ← Diálogo de kill de proceso
├── settings.qml                ← Settings panel entry
├── welcome.qml                 ← First-run experience
├── assets/                     ← SVG icons, imágenes
│   ├── icons/fluent/           ← Fluent UI icon set (SVG)
│   └── images/
├── defaults/                   ← Valores default (ai prompts, etc.)
├── modules/
│   ├── common/                 ← Componentes compartidos entre familias
│   │   ├── functions/          ← ColorUtils, DateUtils, FileUtils, MathUtils
│   │   ├── models/             ← AnimatedTabIndexPair, AdaptedMaterialScheme
│   │   ├── panels/             ← Base panels: lock, polkit, regionSelector
│   │   ├── utils/              ← Appearance, Config, Directories, Persistent, Icons
│   │   └── widgets/            ← 80+ QML widgets reutilizables
│   ├── ii/                     ← Familia de paneles "ii" (Material 3)
│   │   ├── bar/                ← Bar horizontal
│   │   ├── sidebarLeft/        ← Panel izquierdo (AI, translate, anime)
│   │   ├── sidebarRight/       ← Panel derecho (notif, calendar, timer)
│   │   ├── notificationPopup/  ← Toast de notificaciones
│   │   ├── lock/               ← Lock screen visual (ii-specific)
│   │   ├── overview/           ← Workspace overview + search
│   │   ├── mediaControls/      ← Media control popup
│   │   ├── onScreenDisplay/    ← OSD (volumen, brillo)
│   │   ├── onScreenKeyboard/   ← Teclado en pantalla
│   │   ├── overlay/            ← Desktop widgets flotantes
│   │   ├── dock/               ← Dock (opcional)
│   │   ├── cheatsheet/         ← Cheatsheet de keybinds
│   │   ├── sessionScreen/      ← Power/reboot/suspend panel
│   │   ├── polkit/             ← Autenticación polkit
│   │   ├── wallpaperSelector/  ← Selector de wallpaper
│   │   ├── regionSelector/     ← Selección de región (screenshot/OCR)
│   │   ├── screenTranslator/   ← OCR + traducción
│   │   ├── screenCorners/      ← Rounded screen corners
│   │   └── verticalBar/        ← Variante vertical del bar
│   ├── waffle/                 ← Familia alternativa (Windows 11-inspired)
│   │   ├── bar/
│   │   ├── actionCenter/       ← Panel derecho tipo Windows action center
│   │   ├── notificationCenter/
│   │   ├── notificationPopup/
│   │   ├── looks/              ← Looks.qml: design system propio de Waffle
│   │   ├── startMenu/
│   │   ├── taskView/
│   │   ├── lock/
│   │   ├── onScreenDisplay/
│   │   ├── polkit/
│   │   ├── screenSnip/
│   │   └── sessionScreen/
│   └── settings/               ← Settings UI
├── panelFamilies/              ← IllogicalImpulseFamily.qml, WaffleFamily.qml
├── scripts/
│   ├── colors/                 ← switchwall.sh + helpers de matugen
│   ├── hyprland/               ← Scripts de Hyprland IPC
│   ├── ai/                     ← Scripts de AI (gemini, ollama)
│   ├── cava/                   ← Audio visualizer
│   ├── images/                 ← Procesamiento de imágenes
│   ├── thumbnails/             ← Generación de thumbnails
│   └── videos/                 ← Manejo de video wallpaper
└── services/                   ← Singletons de servicios del sistema
    ├── ai/                     ← Servicios de AI
    ├── network/                ← NetworkManager bridge
    ├── gCloud/                 ← Google Cloud (speech)
    └── hyprlandAntiFlashbangShader/ ← Control del shader anti-flashbang
```

---

## Entry point — shell.qml

### Pragmas críticos

```qml
//@ pragma UseQApplication              // QApplication completa (drag-and-drop, system tray)
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic  // ← CRÍTICO: sin esto, Button/TabBar heredan tema de plataforma
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
```

`QT_QUICK_CONTROLS_STYLE=Basic` es el más importante: sin él, cada control QtQuick hereda
el tema nativo de la plataforma, lo que rompe todo el custom styling.

### Boot sequence

```qml
Component.onCompleted: {
    MaterialThemeLoader.reapplyTheme()  // ← los singletons son lazy; esto fuerza el load inicial
    Hyprsunset.load()
    FirstRunExperience.load()
    ConflictKiller.load()
    Cliphist.refresh()
    Wallpapers.load()
    Updates.load()
}
```

`reapplyTheme()` en `Component.onCompleted` es necesario porque `MaterialThemeLoader` es un
singleton lazy — no vigila el archivo de colores hasta que algo lo referencia. Sin este kick,
la UI arranca sin colores aplicados.

---

## Sistema de familias de paneles

ii soporta dos "familias" de paneles intercambiables en runtime: `ii` (Material 3) y `waffle` (Windows 11).

### PanelFamilyLoader — LazyLoader por familia

```qml
property list<string> families: ["ii", "waffle"]

component PanelFamilyLoader: LazyLoader {
    required property string identifier
    property bool extraCondition: true
    active: Config.ready && Config.options.panelFamily === identifier && extraCondition
}

PanelFamilyLoader { identifier: "ii";     component: IllogicalImpulseFamily {} }
PanelFamilyLoader { identifier: "waffle"; component: WaffleFamily {} }
```

Cuando `active: false`, el `LazyLoader` no instancia el componente — cero memoria, cero rendering.
Al cambiar de familia, el árbol de componentes anterior se destruye y el nuevo se crea.

### PanelLoader — guard de Config.ready

Dentro de cada familia, cada panel individual usa `PanelLoader`:

```qml
// PanelLoader.qml
LazyLoader {
    property bool extraCondition: true
    active: Config.ready && extraCondition
}

// Uso en IllogicalImpulseFamily.qml:
PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
PanelLoader { component: SidebarLeft {} }
PanelLoader { component: Bar {} }
```

El guard de `Config.ready` evita race conditions donde los paneles intentan leer config
antes de que el archivo esté cargado.

### Cross-family fallbacks

WaffleFamily importa algunos paneles del namespace de ii directamente cuando no tiene implementación propia:

```qml
// WaffleFamily.qml
import qs.modules.ii.cheatsheet
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overlay
import qs.modules.ii.screenTranslator
import qs.modules.ii.wallpaperSelector
```

Un panel escrito una vez puede ser usado por ambas familias.

---

## GlobalStates.qml — Boolean switchboard

Singleton central. Todo el estado de "abierto/cerrado" de los paneles vive aquí.

```qml
pragma Singleton
Singleton {
    id: root
    property bool barOpen: true
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool overviewOpen: false
    property bool screenLocked: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    // ... 15+ booleans más
}
```

**Principio de diseño:** un panel nunca sabe si está abierto — su `visible` está bindeado
a `GlobalStates.somePanel`. Cualquier código en cualquier parte del shell puede abrir un panel
con `GlobalStates.sidebarLeftOpen = true`.

### Side effects en GlobalStates

Los efectos secundarios del cambio de estado también viven en GlobalStates:

```qml
onSidebarRightOpenChanged: {
    if (GlobalStates.sidebarRightOpen) {
        Notifications.timeoutAll()    // parar timers de popup
        Notifications.markAllRead()   // limpiar contador de no leídos
    }
}
```

### superDown + superReleaseMightTrigger

Par para implementar "tap Super → open search":

- `superDown` = Super está presionado
- `superReleaseMightTrigger` = si se suelta sin otra tecla, abre search

Si el usuario presiona `Super+E` mientras mantiene Super, `superReleaseMightTrigger` se pone en
`false` — el release de Super no abre search porque se usó como modificador, no como tap.

**Diferencia con Caelestia:** Caelestia usa `Visibilities.qml` con un mapa por monitor. ii usa
un boolean compartido — más simple, pero sin soporte de estado per-monitor.

---

## Sistema de visibilidad de paneles

Cada panel sigue este patrón exacto. Cinco piezas que trabajan juntas:

### 1. Boolean en GlobalStates

```qml
property bool sidebarLeftOpen: false
```

### 2. PanelWindow con visible bindeado

```qml
PanelWindow {
    visible: GlobalStates.sidebarLeftOpen
}
```

### 3. GlobalFocusGrab — click fuera para cerrar

```qml
onVisibleChanged: {
    if (visible) {
        GlobalFocusGrab.addDismissable(panelWindow)
    } else {
        GlobalFocusGrab.removeDismissable(panelWindow)
    }
}
Connections {
    target: GlobalFocusGrab
    function onDismissed() { panelWindow.hide() }
}
```

### 4. IpcHandler para control externo

```qml
IpcHandler {
    target: "sidebarLeft"
    function toggle(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
    function close(): void  { GlobalStates.sidebarLeftOpen = false }
    function open(): void   { GlobalStates.sidebarLeftOpen = true }
}
```

### 5. GlobalShortcut para teclado

```qml
GlobalShortcut {
    name: "sidebarLeftToggle"
    onPressed: { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen }
}
```

### GlobalFocusGrab — implementación interna

Un único `HyprlandFocusGrab` gestiona dos listas: `persistent` (bar, OSK — siempre en el grab,
no se cierran) y `dismissable` (sidebars, overview — se cierran al hacer click fuera).

```qml
HyprlandFocusGrab {
    // Si algún dismissable tiene foco activo, incluir también los persistent
    windows: root.dismissable.every(w => !w?.focusable) ||
             root.dismissable.some(w => hasActive(w?.contentItem)) ?
             [...root.dismissable, ...root.persistent] :
             [...root.dismissable]
    active: root.dismissable.length > 0
    onCleared: () => root.dismiss()
}
```

La lógica: si un input tiene foco dentro de un sidebar (estás escribiendo), incluir el bar en
el grab para que no robe el foco mientras escribís.

### Bar auto-hide

El bar usa un mecanismo diferente — `hoverRegion` MouseArea:

```qml
property bool mustShow: hoverRegion.containsMouse || superShow
exclusiveZone: (autoHide && (!mustShow || !pushWindows)) ? 0 : Appearance.sizes.baseBarHeight

anchors.topMargin: (autoHide && !mustShow) ? -Appearance.sizes.barHeight : 0
Behavior on anchors.topMargin {
    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
}
```

`exclusiveZone: 0` cuando está oculto — las ventanas no se reservan espacio. Al hacer hover
cerca del borde, `containsMouse` se activa y el bar se desliza de vuelta.

---

## Config.qml — Hot-reload bidireccional

```qml
pragma Singleton

FileView {
    id: configFileView
    path: Directories.shellConfigPath + "/config.json"
    watchChanges: true
    blockWrites: root.blockWrites
    onFileChanged: fileReloadTimer.restart()     // debounce 50ms antes de leer
    onAdapterUpdated: fileWriteTimer.restart()   // debounce 50ms antes de escribir
    onLoaded: root.ready = true
    onLoadFailed: error => {
        if (error == FileViewError.FileNotFound) writeAdapter()  // crear en primer inicio
    }

    JsonAdapter {
        id: configOptionsJsonAdapter
        property string panelFamily: "ii"
        property JsonObject bar: JsonObject { ... }
        // 25+ secciones top-level
    }
}
```

**Round-trip completo:** escribir `Config.options.panelFamily = "waffle"` → `onAdapterUpdated` →
`fileWriteTimer` → `configFileView.writeAdapter()` → serializa el adapter a JSON en disco.

Los timers de 50ms (`readWriteDelay`) evitan I/O thrashing cuando múltiples propiedades
cambian en el mismo frame.

### setNestedValue — cambios programáticos

```qml
function setNestedValue(nestedKey, value) {
    let keys = nestedKey.split(".")
    let obj = root.options
    // Navega hasta el padre, luego setea la hoja
    // Auto-coerce strings: "true"→bool, "42"→number
}
```

---

## Persistent.qml — Estado que sobrevive qs restart

Separado de Config, guarda estado de runtime que debe persistir entre reloads de Quickshell
pero resetear si Hyprland reinicia.

### Detección de instancia de Hyprland

```qml
property bool isNewHyprlandInstance:
    previousHyprlandInstanceSignature !== states.hyprlandInstanceSignature

onReadyChanged: {
    root.previousHyprlandInstanceSignature = root.states.hyprlandInstanceSignature
    root.states.hyprlandInstanceSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || ""
}
```

Si la firma cambió → Hyprland reinició → resetear todo. Si no → solo fue `qs restart` → preservar estado.

### Qué se persiste en states.json

- Selección de modelo AI + temperatura
- Tab index actual de sidebarLeft y sidebarRight
- Posiciones de widgets overlay flotantes (crosshair, recorder, etc.)
- Estado del pomodoro (corriendo, tiempo de inicio, laps)
- Estado del idle inhibitor

### JsonObject nested — pattern de persistencia

```qml
property JsonObject sidebar: JsonObject {
    property JsonObject bottomGroup: JsonObject {
        property bool collapsed: false
        property int tab: 0
    }
}
// Uso:
Persistent.states.sidebar.bottomGroup.tab = 1  // dispara file write automáticamente
```

`JsonObject` / `JsonAdapter` permiten leer propiedades nested directamente como QML properties
mientras auto-serializan a JSON.

---

## Directories.qml — Centralización de paths

```qml
pragma Singleton

readonly property string home:   StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
readonly property string state:  StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
readonly property string cache:  StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]

// Paths específicos del shell:
property string shellConfig:               FileUtils.trimFileProtocol(`${config}/illogical-impulse`)
property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${state}/user/generated/colors.json`)
property string notificationsPath:         FileUtils.trimFileProtocol(`${cache}/notifications/notifications.json`)
```

`FileUtils.trimFileProtocol()` quita el prefijo `file://` que devuelve `StandardPaths` — necesario
porque `FileView.path`, `Process.command`, etc. quieren paths del filesystem, no URLs.

### Mkdir en Component.onCompleted

```qml
Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
    Quickshell.execDetached(["bash", "-c", `rm -rf '${coverArt}'; mkdir -p '${coverArt}'`])
    // ... otros setup
}
```

---

## Sistema de imports / namespaces

Todos los módulos usan imports URI registrados en archivos `qmldir`:

```qml
import qs                          // GlobalStates, root-level singletons
import qs.modules.common           // Appearance, Config, Directories, Persistent, Icons
import qs.modules.common.functions // ColorUtils, DateUtils, FileUtils, MathUtils
import qs.modules.common.widgets   // Todos los widgets (80+ componentes QML)
import qs.modules.common.models    // AnimatedTabIndexPair, AdaptedMaterialScheme
import qs.services                 // Todos los singletons de servicios del sistema
import qs.modules.ii.bar           // Componentes del bar module
import qs.modules.waffle.looks     // Looks.qml — design system de Waffle
```

Desde `import qs.services` son accesibles por nombre: `Notifications`, `Brightness`,
`Audio`, `MaterialThemeLoader`, etc. (todos con `pragma Singleton`).

---

## Servicios — tabla de referencia rápida

| Servicio | Técnica clave | Notas |
|---|---|---|
| `MaterialThemeLoader` | `FileView watchChanges` + timer delay | `reapplyTheme()` en boot — lazy singleton |
| `GlobalFocusGrab` | Un `HyprlandFocusGrab` con listas persistent/dismissable | Click-fuera-para-cerrar para todos los paneles |
| `Notifications` | `NotificationServer` + `FileView` persistencia + agrupamiento | idOffset evita colisión de IDs |
| `Persistent` | `FileView` + `JsonAdapter` + firma de instancia Hyprland | Dos JSON: `states.json` (transiente) vs `config.json` (usuario) |
| `Directories` | `StandardPaths` + `trimFileProtocol` | `Component.onCompleted` para mkdir/cleanup |
| `HyprlandData` | Parseo de JSON de `hyprctl monitors/clients` | `biggestWindowForWorkspace()` para iconos de workspace |
| `Brightness` | Controladores per-monitor | `getMonitorForScreen(screen)` desde el bar |
| `DateTime` | Uptime, tiempo formateado, estado pomodoro | Usado en el sidebar derecho |

---

## Diferencias clave con Caelestia

| Feature | Caelestia | end-4 ii |
|---|---|---|
| Visibilidad de paneles | `Visibilities.qml` mapa por monitor | Boolean global en `GlobalStates` |
| Fuente de colores | `scheme.json` via CLI `caelestia scheme set` | `colors.json` via `matugen` directamente |
| Config | Desconocida | `JsonAdapter` bidireccional, 50ms debounce |
| Estado persistente | `PersistentProperties` | `Persistent.qml` + tracking de instancia Hyprland |
| Focus grab | `HyprlandFocusGrab` por panel | Un `GlobalFocusGrab` con listas persistent/dismissable |
| Familias de paneles | Una familia | Dos familias intercambiables (ii + waffle) |

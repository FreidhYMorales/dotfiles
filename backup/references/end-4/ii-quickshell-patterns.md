# ii (illogical-impulse) — Quickshell/QML Patterns

Patterns concretos extraídos del source de ii para replicar en una shell propia con Quickshell.
Ver también: [`ii-shell-architecture.md`](ii-shell-architecture.md) para la arquitectura general.

---

## Pattern 1 — Sistema de colores completo (matugen → QML)

### Paso 1: matugen genera el JSON

`matugen` escribe `~/.local/state/quickshell/user/generated/colors.json` en snake_case M3:

```json
{
  "background": "#141313",
  "on_background": "#e6e1e1",
  "surface_container": "#201f20",
  "primary": "#d8bbff"
}
```

### Paso 2: MaterialThemeLoader vigila y aplica

```qml
// MaterialThemeLoader.qml (pragma Singleton)
FileView {
    path: Directories.generatedMaterialThemePath
    watchChanges: true
    onFileChanged: delayedRead.restart()    // delay de Config.options.hacks.arbitraryRaceConditionDelay
}

function applyColors(fileContent) {
    const json = JSON.parse(fileContent)
    for (const key in json) {
        // "on_background" → "onBackground" → "m3onBackground"
        const camelKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
        Appearance.m3colors[`m3${camelKey}`] = json[key]
    }
    Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
}
```

El delay (default 20ms) existe porque el file watcher puede disparar antes de que el archivo
esté completamente escrito a disco.

### Paso 3: Appearance.qml deriva los tokens de diseño

`Appearance.qml` calcula ~60 tokens de color desde `m3colors`. El sistema de capas:

| Token | Fuente M3 | Semántica |
|---|---|---|
| `colLayer0` | `m3background` (transparente) | Base — fondo de bar y sidebars |
| `colLayer1` | `m3surfaceContainerLow` | Cards, grupos dentro de paneles |
| `colLayer2` | `m3surfaceContainer` | Widgets anidados, ítems |
| `colLayer3` | `m3surfaceContainerHigh` | Ítems seleccionados |
| `colLayer4` | `m3surfaceContainerHighest` | Hover sobre ítems |
| `colPrimary` | `m3primary` | Workspace activo, botones |
| `colSecondaryContainer` | `m3secondaryContainer` | Indicador de tab |

Cada capa tiene variantes `Hover` y `Active` computadas mezclando con el color de texto.

### Sistema de transparencia automática

`ColorQuantizer` lee el wallpaper para calcular vibrancia:

```qml
ColorQuantizer {
    source: Qt.resolvedUrl(wallpaperPath)
    depth: 0       // 2^0 = 1 color (solo el color dominante)
    rescaleSize: 10
}
property real wallpaperVibrancy: (colors[0]?.hslSaturation + colors[0]?.hslLightness) / 2

property real autoBackgroundTransparency: {
    let x = wallpaperVibrancy
    let y = 0.5768 * (x * x) - 0.759 * (x) + 0.2896
    return Math.max(0, Math.min(0.22, y)) - 0.12 * (m3colors.darkmode ? 0 : 1)
}
```

Wallpapers vibrantes → bar más transparente. Wallpapers apagados → bar más opaco.

### solveOverlayColor — capas semi-transparentes matemáticamente correctas

`ColorUtils.solveOverlayColor(base, target, opacity)` invierte la ecuación de compositing:
dado que quiero que `overlay` se vea como `target` cuando se compone sobre `base`,
¿qué valor RGBA debe tener `overlay`?

```qml
// ColorUtils.qml:
function solveOverlayColor(baseColor, targetColor, overlayOpacity) {
    // result = overlay * overlayOpacity + base * (1 - overlayOpacity)
    // Solve for overlay:
    let r = (tc.r - bc.r * invA) / overlayOpacity
    // ...
}

// Usado en Appearance:
property color colLayer2: ColorUtils.solveOverlayColor(colLayer1Base, colLayer2Base, 1 - contentTransparency)
```

Esto garantiza que con transparencia activada, las capas visualmente coinciden con el spec M3
aunque sean semi-transparentes.

### Inventario de ColorUtils

| Función | Firma | Uso |
|---|---|---|
| `mix` | `(c1, c2, pct=0.5)` | pct=1 → todo c1, pct=0 → todo c2 |
| `transparentize` | `(color, pct=1)` | Multiplica alpha por (1-pct) |
| `applyAlpha` | `(color, alpha)` | Setea alpha directo |
| `solveOverlayColor` | `(base, target, opacity)` | Invierte ecuación de compositing |
| `adaptToAccent` | `(c1, c2)` | Luminosidad de c1 + hue/sat de c2 |
| `colorWithHueOf` | `(c1, c2)` | Transferencia de hue HSV |
| `isDark` | `(color)` | `hslLightness < 0.5` |

### AdaptedMaterialScheme — colores locales por acento

Para notificaciones con su propio color de acento:

```qml
QtObject {
    required property color color   // el acento de la app
    property color colLayer0: ColorUtils.mix(Appearance.colors.colLayer0, root.color, 0.5)
    property color colPrimary: ColorUtils.mix(
        ColorUtils.adaptToAccent(Appearance.colors.colPrimary, root.color),
        root.color, 0.5)
}
```

`adaptToAccent` toma la luminosidad de c1 y el hue+saturation de c2 — tinta un color hacia
un acento manteniendo legibilidad.

---

## Pattern 2 — AnimatedTabIndexPair: el pill elástico

El componente más original de ii. Crea un indicador que se estira como goma entre posiciones.

```qml
// models/AnimatedTabIndexPair.qml
QtObject {
    required property real index
    property real idx1Duration: 50     // borde que va hacia delante — snap rápido
    property real idx2Duration: 200    // borde que va hacia atrás — sigue lento

    property real idx1: 0
    property real idx2: 0

    Behavior on idx1 { NumberAnimation { duration: root.idx1Duration } }
    Behavior on idx2 { NumberAnimation { duration: root.idx2Duration } }

    onIndexChanged: { idx1 = index; idx2 = index }
}
```

### Uso en ToolbarTabBar (sidebarLeft)

El indicador visual de tab es un Rectangle invisible que usa dos `AnimatedTabIndexPair`:

```qml
AnimatedTabIndexPair { id: leftBound;  index: activeIndicator.targetItem.x }
AnimatedTabIndexPair { id: rightBound; index: activeIndicator.targetItem.x + activeIndicator.targetItem.width }

// El Rectangle:
x: Math.min(leftBound.idx1, leftBound.idx2)
width: Math.max(rightBound.idx1, rightBound.idx2) - x
```

El borde izquierdo toma el mínimo de los dos valores (snappa al nuevo lado rápido).
El borde derecho toma el máximo (se queda atrás). Resultado: el pill se expande hacia el destino
y luego se contrae → efecto goma.

El `TabBar` real queda invisible (`z: -1`), solo se usa para la lógica de índice.

### Uso en indicador de workspace (bar)

El mismo pattern para el workspace activo:

```qml
AnimatedTabIndexPair {
    id: idxPair
    index: root.workspaceIndexInGroup
}
property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * workspaceButtonWidth + margin
property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * workspaceButtonWidth + workspaceButtonWidth - margin * 2
```

Al cambiar de workspace, el pill se estira entre el origen y el destino.

### Workspaces ocupados — radios inteligentes

Los workspaces con ventanas muestran un highlight que une workspaces adyacentes en una banda:

```qml
property var radiusPrev: previousOccupied ? 0 : (width / 2)
property var radiusNext: rightOccupied    ? 0 : (width / 2)
topLeftRadius:    radiusPrev
bottomLeftRadius: radiusPrev
topRightRadius:   radiusNext
bottomRightRadius: radiusNext
```

Si el workspace anterior también está ocupado, ese borde no tiene redondeo — los dos ítem
se ven como un solo píldora continua.

---

## Pattern 3 — Sistema de tabs (dos implementaciones)

### SidebarLeft: ToolbarTabBar + SwipeView con tabs dinámicos

Los tabs se construyen desde config flags:

```qml
property var tabButtonList: [
    ...(root.aiChatEnabled     ? [{"icon": "neurology",  "name": "Intelligence"}] : []),
    ...(root.translatorEnabled ? [{"icon": "translate",  "name": "Translator"}]   : []),
    ...(root.animeEnabled      ? [{"icon": "bookmark_heart", "name": "Anime"}]    : [])
]

SwipeView {
    contentChildren: [
        ...(root.aiChatEnabled     ? [aiChat.createObject()]   : []),
        ...(root.translatorEnabled ? [translator.createObject()] : []),
    ]
}
```

El SwipeView usa `OpacityMask` con un `Rectangle` para redondear el contenido sin clip duro:

```qml
layer.enabled: true
layer.effect: OpacityMask {
    maskSource: Rectangle {
        width: swipeView.width; height: swipeView.height
        radius: Appearance.rounding.small
    }
}
```

### SidebarRight bottom: NavigationRail + Loader con animación

Tres tabs (Calendar / To-Do / Timer) usan un `Loader` que cambia de `source`:

```qml
property var tabs: [
    { "type": "calendar", "widget": "calendar/CalendarWidget.qml" },
    { "type": "todo",     "widget": "todo/TodoWidget.qml" },
    { "type": "timer",    "widget": "pomodoro/PomodoroWidget.qml" },
]

Loader {
    id: tabStack
    Connections {
        function onSelectedTabChanged() {
            tabStack.source = root.tabs[root.selectedTab].widget
        }
    }
}
```

### TabSwitchAnim — fade + slide con cambio en medio

```qml
component TabSwitchAnim: SequentialAnimation {
    property bool down: false
    ParallelAnimation { /* fade out + slide hacia dirección */ }
    PropertyAction {}  // ← aquí cambia source (frame boundary invisible)
    ParallelAnimation { /* fade in + slide desde dirección opuesta */ }
}
```

`PropertyAction {}` sin propiedades inserta un frame boundary — el contenido nuevo ya está
cargado cuando empieza la animación de entrada.

El tab index se guarda en `Persistent.states.sidebar.bottomGroup.tab` en cada cambio.

---

## Pattern 4 — Bar arquitectura

### Variantes por monitor

```qml
Variants {
    model: {
        const screens = Quickshell.screens
        const list = Config.options.bar.screenList
        if (!list || list.length === 0) return screens   // todas las pantallas
        return screens.filter(screen => list.includes(screen.name))
    }
    LazyLoader {
        id: barLoader
        active: GlobalStates.barOpen && !GlobalStates.screenLocked
        required property ShellScreen modelData
        component: PanelWindow {
            screen: barLoader.modelData
        }
    }
}
```

El bar se oculta (`active: false`) durante el lock screen.

### Layout de tres regiones

`BarContent.qml` usa tres regiones donde el centro es genuinamente centrado:

- **Left side** — anclado `left + right: middleSection.left`. Scroll cambia brillo. Click abre sidebarLeft.
- **Middle section** — `anchors.horizontalCenter: parent.horizontalCenter`. Contiene recursos/media, workspaces, reloj/batería.
- **Right side** — anclado `left: middleSection.right + right`. Scroll cambia volumen. Click abre sidebarRight.

Los grupos left-center y right-center tienen anchos fijos (`centerSideModuleWidth`) para mantener
el middle centrado incluso cuando el contenido cambia. En pantallas <1200px los anchos se achican.

### BarGroup — primitivo visual de agrupación

```qml
Item {
    property real padding: 5
    default property alias items: gridLayout.children  // ← default property!

    Rectangle { color: Appearance.colors.colLayer1; radius: Appearance.rounding.small }
    GridLayout {
        columns: root.vertical ? 1 : -1    // -1 = columnas ilimitadas (flujo horizontal)
        columnSpacing: 4; rowSpacing: 12
    }
}
```

`default property alias items` significa que cualquier hijo declarado dentro de `BarGroup {}`
automáticamente va al GridLayout — pattern estándar de QML.

### Brillo per-monitor desde el bar

```qml
property var screen: root.QsWindow.window?.screen
property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
```

`QsWindow.window?.screen` es el pattern para obtener el `ShellScreen` desde dentro de un `PanelWindow`.

---

## Pattern 5 — Sistema de notificaciones completo

### Wrapper Notif por notificación

```qml
component Notif: QtObject {
    required property int notificationId  // server ID + idOffset
    property Notification notification    // objeto nativo de Quickshell
    property bool popup: false            // actualmente mostrando como toast
    property bool isTransient: notification?.hints.transient ?? false
    property Timer timer                  // timeout per-notificación
    property double time                  // JS Date.now() al arribar
    // Aplanados desde notification para serialización JSON:
    property string appName, appIcon, body, image, summary, urgency
}
```

### idOffset — prevención de colisiones de ID

Quickshell's `NotificationServer` resetea IDs a 1 en cada inicio. Las notificaciones
guardadas en disco pueden tener IDs mayores. El `idOffset` = max ID guardado garantiza
que las nuevas siempre tengan IDs únicos:

```qml
root.idOffset = maxId  // desde el archivo cargado
// Nuevo ID de notificación: notification.id + root.idOffset
```

### Agrupamiento por app

```qml
property var groupsByAppName: groupsForList(root.list)           // todas las notifs
property var popupGroupsByAppName: groupsForList(root.popupList) // solo popups
property list<string> appNameList: appNameListForGroups(...)     // ordenadas por tiempo desc
```

### Inhibición de popup

```qml
popupInhibited: (GlobalStates?.sidebarRightOpen ?? false) || silent
```

Cuando el sidebar está abierto, las nuevas notificaciones van directo a la lista sin popup.

### NotificationPopup — monitor seguido

El popup sigue al monitor con foco:

```qml
PanelWindow {
    visible: (Notifications.popupList.length > 0) && !GlobalStates.screenLocked
    screen: Quickshell.screens.find(s =>
        Config.options.notifications.forceMonitor.enable ?
        s.name === Config.options.notifications.forceMonitor.name :
        s.name === Hyprland.focusedMonitor?.name
    ) ?? null

    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region { item: listview.contentItem }  // solo interactivo donde hay contenido
}
```

`mask: Region { item: ... }` es crítico — el window ocupa todo el borde derecho del monitor
pero solo captura input donde están las notificaciones reales.

### NotificationGroup — drag para dismiss

- **Hover**: cancela el timeout
- **Right-click**: expand/collapse el grupo
- **Middle-click**: dismiss inmediato con animación
- **Drag**: swipe izquierda/derecha para dismiss

Las notificaciones adyacentes se mueven al 30% / 10% del drag (como Android):

```qml
property real xOffset: dragIndexDiff == 0 ? parentDragDistance :
    Math.abs(parentDragDistance) > dragConfirmThreshold ? 0 :
    dragIndexDiff == 1 ? (parentDragDistance * 0.3) :
    dragIndexDiff == 2 ? (parentDragDistance * 0.1) : 0
```

La animación de dismiss desliza la notif fuera de pantalla, luego llama `discardNotification`
via `Qt.callLater` para evitar modificar el model durante la animación.

---

## Pattern 6 — Lock screen en tres capas

### Separación de responsabilidades

1. **`LockScreen.qml`** (common/panels) — base: `WlSessionLock` + `LockContext` + IPC/shortcuts
2. **`LockContext.qml`** (common/panels) — estado compartido: password, PAM, fingerprint, acción target
3. **`LockSurface.qml`** (modules/ii/lock) — presentación visual específica de ii

**Por qué la separación:** `WlSessionLock` crea una `WlSessionLockSurface` por monitor.
Todas las superficies deben compartir el mismo estado de password (escribir en monitor A
actualiza el campo en monitor B). `LockContext` se instancia una vez y se pasa como
`required property LockContext context` a cada superficie.

### WlSessionLock binding

```qml
WlSessionLock {
    locked: GlobalStates.screenLocked   // binding: setear true activa el lock
    surface: root.sessionLockSurface
}
```

### Ocultamiento de workspaces al lockear

ii mueve todos los workspaces a IDs altísimos (2147483647) para que las ventanas no sean
visibles a través del lock:

```qml
function onScreenLockedChanged() {
    if (GlobalStates.screenLocked) {
        var batch = "keyword animation workspaces,1,7,menu_decel,slidevert; "
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var ws = mData?.activeWorkspace?.id ?? 1
            next[mon] = ws   // guardar para restore
            batch += `hyprctl dispatch 'hl.dsp.focus({workspace=${2147483647 - ws}})';`
        }
        Quickshell.execDetached(["bash", "-c", batch])
    } else {
        restoreTimer.start()  // 150ms delay, luego restore
    }
}
```

### PAM + fingerprint

```qml
// Password:
PamContext {
    onCompleted: result => {
        if (result == PamResult.Success) root.unlocked(root.targetAction)
        else { root.clearText(); GlobalStates.screenUnlockFailed = true }
    }
}

// Fingerprint (corre en paralelo):
PamContext {
    configDirectory: "pam"; config: "fprintd.conf"
    onCompleted: result => {
        if (result == PamResult.Success) root.unlocked(root.targetAction)
        else if (result == PamResult.Error) tryFingerUnlock()  // reintentar en timeout
    }
}
```

### Error shake animation

```qml
ErrorShakeAnimation { id: wrongPasswordShakeAnim; target: passwordBox }
Connections {
    target: GlobalStates
    function onScreenUnlockFailedChanged() {
        if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart()
    }
}
```

### Estructura visual del lock surface (ii)

Tres "islas" Toolbar ancladas al fondo:
- **Izquierda:** username + keyboard layout
- **Centro:** fingerprint icon + password input + confirm button
- **Derecha:** battery + sleep/power/reboot buttons

Las islas aparecen con pop-in: `toolbarScale: 0.9 → 1.0`, `toolbarOpacity: 0 → 1`.

---

## Pattern 7 — Sistema de animaciones (Component como factory)

`Appearance.animation` guarda definiciones como objetos con `numberAnimation: Component`.

```qml
// Uso en cualquier Behavior:
Behavior on width {
    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
}
```

`createObject(this)` crea una instancia de `NumberAnimation` en el call site.
`this` es el objeto `Behavior`. Esto permite centralizar las definiciones sin herencia.

### Taxonomía de animaciones

| Nombre | Duración | Curva | Caso de uso |
|---|---|---|---|
| `elementMove` | 500ms | `expressiveDefaultSpatial` | Elementos reposicionándose |
| `elementMoveSmall` | 350ms | `expressiveFastSpatial` | Movimientos pequeños |
| `elementMoveEnter` | 400ms | `emphasizedDecel` | Animaciones de entrada |
| `elementMoveExit` | 200ms | `emphasizedAccel` | Animaciones de salida |
| `elementMoveFast` | 200ms | `expressiveEffects` | Color, opacidad, transiciones rápidas |
| `elementResize` | 300ms | `emphasized` | Cambios de tamaño |
| `clickBounce` | 400ms | `expressiveDefaultSpatial` | Bounce de botón presionado |
| `scroll` | 200ms | `standardDecel` | Posición de scroll |
| `menuDecel` | 350ms | `OutExpo` | Aparición de menús |

**Lógica de curvas:**
- `emphasizedDecel` (`[0.05, 0.7, 0.1, 1, 1, 1]`) — empieza lento, termina rápido → entrada (el elemento "llega" con energía)
- `emphasizedAccel` (`[0.3, 0, 0.8, 0.15, 1, 1]`) — empieza rápido, termina lento → salida (el elemento "parte" con impulso)

---

## Pattern 8 — Biblioteca de widgets clave

### Revealer — show/hide con animación (estilo GTK)

```qml
Item {
    property bool reveal
    property bool vertical: false
    clip: true

    implicitWidth:  (reveal || vertical)  ? childrenRect.width  : 0
    implicitHeight: (reveal || !vertical) ? childrenRect.height : 0
    visible: reveal || (implicitWidth > 0 && !vertical) || (implicitHeight > 0 && vertical)

    Behavior on implicitWidth  { /* enter animation si !vertical */ }
    Behavior on implicitHeight { /* enter animation si vertical */ }
}
```

Cuando `reveal` es false, `implicitWidth/Height` anima a 0 — el hijo queda renderizado
pero el contenedor se achica, luego `visible` va a false cuando el tamaño llega a 0.

### FadeLoader — lazy component con fade

```qml
Loader {
    property bool shown: true
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0   // se destruye cuando está completamente oculto

    Behavior on opacity { /* elementMoveFast */ }
}
```

Tanto `visible` como `active` trackean la opacidad. El componente se destruye cuando la
animación de fade out completa — no solo invisible, sino deallocated.

### MaterialSymbol — icono variable font animado

```qml
StyledText {
    property real fill: 0    // 0 = outlined, 1 = filled

    font {
        family: "Material Symbols Rounded"
        variableAxes: { "FILL": truncatedFill, "opsz": iconSize }
    }
    Behavior on fill { NumberAnimation { duration: 200 } }
}
```

Los íconos animan entre filled/outlined. `truncatedFill: fill.toFixed(1)` evita lookups
continuos del font atlas en valores fraccionarios.

### StyledText — texto con animación de cambio

Tiene `animateChange: bool` que dispara slide+fade cuando `text` cambia:

1. Slide up + fade out el texto actual
2. `PropertyAction {}` — el valor cambia aquí (invisible)
3. Posición reset a abajo del original
4. Slide up a posición original + fade in

Crea el efecto "rolling number". Usado para el reloj y números de workspace.

### BarGroup default property

Ver Pattern 4 — `default property alias items` en `BarGroup.qml`.

---

## Pattern 9 — Waffle family: design system propio

`Looks.qml` es el equivalente de `Appearance.qml` para la familia Waffle.
Usa colores fijos Windows 11 style (no derivados de M3) pero hereda el acento de M3:

```qml
darkColors: QtObject {
    property color bg0: "#1C1C1C"
    property color bg1: "#2C2C2C"
    property color bg1Hover: "#292929"
}
lightColors: QtObject {
    property color bg0: "#EEEEEE"
}
colors: QtObject {
    property color bg1: ColorUtils.solveOverlayColor(bg0Base, bg1Base, 1 - contentTransparency)
    property color accent: Appearance.colors.colPrimary  // ← hereda el acento de M3
}
```

### WBarAttachedPanelContent — animación propia de paneles

Los paneles de Waffle se animan a sí mismos (no dependen de Hyprland layer rules):

```qml
property real sourceEdgeMargin: -(implicitHeight + root.visualMargin)  // off-screen

OpenAnim { id: openAnim; properties: "sourceEdgeMargin, sideEdgeMargin" }
// Component.onCompleted: openAnim.start() → slide a 0
// close(): closeAnim → slide de vuelta a negativo, luego emite closed signal
```

Cross-compositor: funciona sin Hyprland-specific layer animation rules.

### ActionCenterContext — StackView navigation desacoplada

```qml
Singleton {
    property StackView stackView
    function push(component) { stackView?.push(component) }
    function back() { if (stackView?.depth > 1) stackView.pop() }
}
// Uso desde cualquier widget dentro del action center:
ActionCenterContext.push(wifiControl)
```

Un botón no necesita saber dónde está en la jerarquía para navegar a una subpágina de settings.

---

## Pattern 10 — SidebarLeft detach: re-parenting de contenido

SidebarLeft puede "desprenderse" del layer shell y convertirse en una FloatingWindow:

```qml
onDetachChanged: {
    if (root.detach) {
        GlobalFocusGrab.removeDismissable(sidebarLoader.item)
        sidebarContent.parent = null         // desanclar de layer panel
        sidebarLoader.active = false         // destruir layer panel
        detachedSidebarLoader.active = true  // crear floating window
        detachedSidebarLoader.item.contentParent.children = [sidebarContent]
    } else {
        sidebarContent.parent = null
        detachedSidebarLoader.active = false
        sidebarLoader.active = true
        sidebarLoader.item.contentParent.children = [sidebarContent]
    }
}
```

**Técnica clave:** `sidebarContent` se crea una sola vez y se re-parentea entre el layer panel
y el floating window. El objeto nunca se destruye → todo el estado (historial de chat AI,
tab actual) se preserva a través de la transición detach/attach.

### Pin mode — exclusiveZone dinámico

```qml
exclusiveZone: root.pin ? sidebarWidth : 0
```

Cuando está pinned, empuja las ventanas. Sin pin, las ventanas van por encima del sidebar.

---

## Pattern 11 — Overview: workspace + search combinados

```qml
Column {
    SearchWidget { id: searchWidget }
    Loader {
        active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
        sourceComponent: OverviewWidget {
            visible: (panelWindow.searchingText == "")  // se oculta al buscar
        }
    }
}
```

### Pre-fill para clipboard/emoji

```qml
function toggleClipboard() {
    overviewScope.dontAutoCancelSearch = true
    panelWindow.setSearchingText(Config.options.search.prefix.clipboard)  // ";"
    GlobalStates.overviewOpen = true
}
```

Abre el overview con el prefix ya escrito → el usuario ve directamente los ítems del clipboard.

### ScreencopyView lazy

```qml
captureSource: GlobalStates.overviewOpen ? root.toplevel : null
```

Los captures se toman solo mientras el overview está abierto — cero overhead de rendering
cuando está cerrado.

---

## Pattern 12 — Pipeline de colores: switchwall.sh

Orden de ejecución al cambiar wallpaper:

1. `gsettings set org.gnome.desktop.interface color-scheme ...` — GTK dark/light
2. `matugen apply --wallpaper <path>` — genera M3 palette JSON + configs de hyprlock, fuzzel, GTK
3. `generate_colors_material.py` — terminal colors + `color.txt` (hex accent)
4. `applycolor.sh` — targets adicionales
5. **(async)** `kde-material-you-colors` + VS Code color scheme

**Auto-detección de scheme:** cuando `palette.type = "auto"`, `scheme_for_image.py` clasifica
la imagen con un modelo Python y elige la variante M3 apropiada.

**Video wallpaper:** detecta `.mp4`/`.webm`, extrae primer frame con `ffmpeg` para generar
colores, luego corre `mpvpaper` en todos los monitores.

**Nota:** `Appearance.qml` computa la transparencia auto-adaptativa en QML desde el wallpaper
via `ColorQuantizer` — independiente del script. La transparencia del bar cambia en tiempo real
sin esperar a que el script termine.

---

## Patterns extractables — prioridad para shell propio

1. **`AnimatedTabIndexPair` + dual-speed indicator** — copiar tal cual para cualquier tab/workspace que necesite el efecto pill elástico.

2. **`GlobalFocusGrab` con listas persistent/dismissable** — un solo `HyprlandFocusGrab` para todos los paneles. Mucho mejor que grabs por panel.

3. **`solveOverlayColor`** — capas semi-transparentes matemáticamente correctas. Esencial para el sistema de transparencia.

4. **`Revealer` widget** — clip + animación de `implicitWidth/Height` con visibility ligada a `opacity > 0`.

5. **`FadeLoader`** — `active: opacity > 0` destruye el componente cuando está completamente oculto.

6. **`TabSwitchAnim`** — `SequentialAnimation` con `PropertyAction {}` vacío como frame boundary para cambiar source en medio de la animación.

7. **`Component` como animation factory** — `animation: Appearance.animation.X.numberAnimation.createObject(this)`. Definiciones centralizadas sin herencia.

8. **Lock screen `LockContext` compartido** — un objeto de contexto pasado como `required property` a todas las superficies por monitor. Todas comparten el mismo estado de password.

9. **idOffset en notificaciones** — evita colisión de IDs entre notificaciones guardadas y nuevas.

10. **Detach por re-parenting** — preservar estado UI al mover contenido entre layer panel y floating window seteando `parent = null` y reasignando `children`.

11. **`Variants` con filter de pantallas** — `screens.filter(screen => list.includes(screen.name))`. Lista vacía = todas las pantallas.

12. **Radios de workspace por adyacencia** — `previousOccupied ? 0 : width/2` en `topLeftRadius/bottomLeftRadius` crea bandas continuas sin código extra.

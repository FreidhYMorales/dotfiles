# Caelestia — Quickshell/QML Patterns

Patterns concretos extraídos del source de Caelestia para replicar en dotfiles propios con Quickshell.
Ver también: [`caelestia-shell-architecture.md`](caelestia-shell-architecture.md) para la arquitectura general.

---

## Pattern 1 — Singleton de colores con FileView + transparencia dinámica

El patrón más importante de toda la shell. Un singleton vigila el archivo de scheme en disco
y propaga cambios a todos los componentes sin reiniciar nada.

```qml
// services/Colours.qml
pragma Singleton

QtObject {
    // 1. Vigila el scheme en disco
    readonly property FileView schemeFile: FileView {
        path: `${Paths.state}/scheme.json`
        watchChanges: true
        onTextChanged: root.load(text(), false)
    }

    // 2. Dos paletas: raw y con transparencia
    readonly property M3Palette palette: M3Palette {}        // raw hex → texto, iconos
    readonly property M3TPalette tPalette: M3TPalette {}     // transparencia → fondos

    // 3. La capa de transparencia usa la luminosidad del wallpaper
    property real wallLuminance: 0.5   // actualizado por ImageAnalyser

    function layer(color, layerIndex) {
        if (layerIndex === 0)
            return Qt.alpha(color, transparency.base)
        // Ajusta luminance según modo claro/oscuro + wallLuminance, luego aplica alpha
        return Qt.hsla(alterLightness(color), Qt.alpha(color, transparency.layers))
    }
}
```

**Para dotfiles propios con matugen:** misma estructura. El FileView apunta al `colors.json`
de matugen. La función `layer()` puede ser más simple si no querés transparencia dinámica.

---

## Pattern 2 — `Variants` para instanciar por pantalla

Quickshell-specific. Crea una instancia del scope por cada item del model.
Equivalente más limpio que `Repeater` + `Scope`.

```qml
// Drawers.qml
pragma ComponentBehavior: Bound

Variants {
    model: Screens.screens   // una instancia completa de la shell por pantalla

    delegate: Scope {
        required property ShellScreen modelData

        Exclusions { screen: modelData }
        ContentWindow { screen: modelData }
    }
}
```

Usar siempre con `pragma ComponentBehavior: Bound` para que las properties del delegate
estén correctamente scoped.

---

## Pattern 3 — `IpcHandler` para comandos desde Hyprland

Permite llamar funciones del shell desde cualquier contexto externo (terminal, keybinds, scripts).

```qml
// En cualquier módulo QML
IpcHandler {
    target: "drawers"

    function toggle(drawer: string): void {
        const vis = Visibilities.getForActive()
        vis[drawer] = !vis[drawer]
    }

    function list(): var {
        return ["bar", "dashboard", "launcher", "session", "sidebar", "utilities", "osd"]
    }
}
```

```bash
# Desde terminal o Hyprland exec:
caelestia drawers toggle launcher
caelestia toaster info "Hello from script"
```

Definir un `IpcHandler` por dominio (drawers, audio, brightness, etc.) para mantener
la API organizada. Los métodos son directamente las funciones QML.

---

## Pattern 4 — `CustomShortcut` + Hyprland global binds

Para keybinds que necesitan estar activos siempre (sin depender del foco).

```qml
// components/misc/CustomShortcut.qml
// Wrapper de Quickshell.Shortcut para registrar en Hyprland
CustomShortcut {
    name: "launcher"
    onReleased: Visibilities.getForActive().launcher = !Visibilities.getForActive().launcher
}
```

```conf
# hyprland keybinds.conf
bindi = Super, Super_L, global, caelestia:launcher
bind  = ,XF86PowerOff, global, caelestia:lock
```

El `name` en `CustomShortcut` debe coincidir con la parte después de `caelestia:` en el bind.

---

## Pattern 5 — `DrawerVisibilities` con `PersistentProperties`

Estado de visibilidad por pantalla que sobrevive reloads del shell.

```qml
// components/DrawerVisibilities.qml
PersistentProperties {
    reloadableId: `drawers-${screen.name}`   // único por pantalla

    property bool bar: false
    property bool osd: false
    property bool launcher: false
    property bool dashboard: false
    property bool session: false
    property bool sidebar: false
    property bool utilities: false
}
```

```qml
// services/Visibilities.qml — map global pantalla → visibilidades
pragma Singleton

QtObject {
    property var map: ({})

    function register(screen: ShellScreen, vis: DrawerVisibilities): void {
        map[screen.name] = vis
    }

    function getForActive(): DrawerVisibilities {
        return map[Hypr.focusedMonitor?.name] ?? map[Object.keys(map)[0]]
    }
}
```

El `Hypr.focusedMonitor` garantiza que los atajos de teclado afecten la pantalla correcta.

---

## Pattern 6 — Sistema de animaciones M3 con tipos semánticos

En vez de hardcodear duraciones y easings, usar un type system con nombres semánticos.

```qml
// components/Anim.qml
NumberAnimation {
    enum Type {
        Standard,          // normal UI transitions
        Emphasized,        // elementos que entran/salen del viewport
        DefaultSpatial,    // movimientos de paneles
        FastSpatial,       // respuestas a input directo
        SlowSpatial        // transiciones de pantalla completa
    }

    property int type: Anim.Standard

    duration: Tokens.anim.durations[typeNames[type]]
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Tokens.anim.curves[typeNames[type]]
}

// CAnim.qml — igual pero para ColorAnimation
ColorAnimation {
    duration: Tokens.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Tokens.anim.curves.standard
}
```

Uso:
```qml
// Behavior shorthand
Behavior on opacity { Anim { type: Anim.Standard } }
Behavior on color   { CAnim {} }

// En transiciones de estado
Transition {
    from: ""; to: "visible"
    Anim { target: root; property: "implicitWidth"; type: Anim.DefaultSpatial }
}
```

---

## Pattern 7 — `StyledRect` con color animado built-in

Componente base para todo fondo. Agrega `Behavior on color { CAnim {} }` automáticamente,
así todo cambio de color es suave sin escribirlo en cada sitio.

```qml
// components/StyledRect.qml
Rectangle {
    Behavior on color { CAnim {} }
}

// Uso — el cambio de color será siempre animado:
StyledRect {
    color: Colours.tPalette.m3surfaceContainer
}
```

Para dotfiles propios: hacer lo mismo con el componente base de fondo. Una línea de
`Behavior on color` en el base ahorra cientos de repeticiones.

---

## Pattern 8 — `StateLayer` (ripple + hover Material 3)

Un `MouseArea` que renderiza ripple de press y overlay de hover/pressed siguiendo spec M3.

```qml
// components/StateLayer.qml
MouseArea {
    id: root
    property color rippleColor: Colours.palette.m3onSurface
    property real hoverOpacity: 0.08
    property real pressedOpacity: 0.12

    // Overlay de hover/pressed
    Rectangle {
        color: Qt.alpha(root.rippleColor, root.pressed ? pressedOpacity : root.hovered ? hoverOpacity : 0)
        Behavior on color { CAnim {} }
    }

    // Ripple circle expandiéndose desde punto de press
    Shape {
        ShapePath {
            fillGradient: RadialGradient {
                // Centro = punto de click, radio se expande a esquina más lejana
            }
        }
    }
}
```

Se usa como overlay encima de cualquier elemento clickeable. Ver `controls/IconButton.qml`.

---

## Pattern 9 — `Loader { asynchronous: true }` para no bloquear

Todos los componentes pesados o de carga lazy usan `asynchronous: true`.

```qml
// Bar entry point
Loader {
    asynchronous: true
    active: entry.enabled
    sourceComponent: entryComponents[entry.id]
}

// Background components
Loader {
    asynchronous: true
    active: Config.background.wallpaperEnabled
    sourceComponent: Wallpaper {}
}
```

Esto permite que la shell arranque visualmente rápido mientras los componentes pesados
(wallpaper, workspaces, iconos de tray) cargan en background.

---

## Pattern 10 — Per-screen config con `contentItem.Config`

La config global está en un `GlobalConfig` singleton. La config por pantalla se pasa
como `attached property` a través de los componentes.

```qml
// Acceso en cualquier componente dentro de ContentWindow:
property var config: contentItem.Config    // config de esta pantalla específica
property var globalConfig: GlobalConfig    // config global

// Tokens de diseño (spacing, rounding, font sizes, anim curves):
property var tokens: Tokens               // attached property, siempre disponible
```

---

## Pattern 11 — Hover/drag routing con un solo MouseArea

Un `CustomMouseArea` a pantalla completa maneja toda la interacción para abrir/cerrar paneles.
Sin listeners individuales en cada panel — un solo lugar que decide qué panel activar.

```qml
// modules/drawers/Interactions.qml
CustomMouseArea {
    anchors.fill: parent
    z: 1000   // encima de todo

    // Detecta en qué zona de la pantalla está el cursor/drag
    function inLeftPanel(x, y): bool { return x < barWidth + threshold }
    function inRightPanel(x, y): bool { return x > parent.width - threshold }
    function inTopPanel(x, y): bool { return y < topThreshold }

    onDragStarted: { dragStartX = mouseX; dragStartY = mouseY }

    onPositionChanged: {
        if (dragging && mouseX - dragStartX > Config.bar.dragThreshold)
            visibilities.bar = true
        if (dragging && dragStartY - mouseY > Config.dashboard.dragThreshold)
            visibilities.dashboard = true
        // etc.
    }
}
```

---

## Pattern 12 — `PersistentProperties` para estado que sobrevive reloads

```qml
// services/GameMode.qml
pragma Singleton

PersistentProperties {
    reloadableId: "gameMode"
    property bool enabled: false

    onEnabledChanged: {
        if (enabled) {
            Hypr.extras.applyOptions({
                "animations:enabled": "0",
                "decoration:blur:enabled": "0",
                "general:gaps_in": "0",
                "general:gaps_out": "0"
            })
        } else {
            Hypr.extras.message("reload")   // reload completo para restaurar
        }
    }
}
```

Usar `PersistentProperties` para: DND toggle, game mode, recorder state, player seleccionado
manualmente. Todo lo que debe sobrevivir un `qs reload`.

---

## Pattern 13 — Workspace groups con script fish

```fish
# hypr/scripts/wsaction.fish
# Argumentos: <action> <wsIndex> <groupIndex>
# workspace 3 en grupo 2 → workspace 23

set ws (math "$argv[3] * 10 + $argv[2]")
hyprctl dispatch $argv[1] $ws
```

```conf
# keybinds.conf
bind = Super, 1, exec, wsaction.fish workspace 1 $currentGroup
bind = Super+Shift, 1, exec, wsaction.fish movetoworkspacesilent 1 $currentGroup
```

---

## Patterns de estructura QML

### `pragma ComponentBehavior: Bound`
Siempre en archivos con `Repeater`/`Variants`. Garantiza que los delegates no puedan
acceder implícitamente a propiedades del contexto externo — fuerza pasar todo
explícitamente como `required property`.

### `required property`
Preferido sobre el contexto implícito de QML:
```qml
// Bien: explícito y type-safe
required property ShellScreen screen
required property DrawerVisibilities visibilities

// Mal: depende del contexto implícito
// visibilities accedido desde contexto padre
```

### Inline `component` para tipos locales sin archivo
```qml
// services/Colours.qml
component M3Palette: QtObject {
    property color m3primary: "transparent"
    property color m3secondary: "transparent"
    property color m3surface: "transparent"
    // ...todos los tokens M3
}

// services/Brightness.qml
component Monitor: QtObject {
    required property string output
    property real brightness: 1.0
}
```

### `Loader` como feature flag
```qml
Loader {
    active: Config.background.desktopClock.enabled
    asynchronous: true
    sourceComponent: DesktopClock {}
}
```

---

## Qué vale replicar para dotfiles propios con Quickshell

| Pattern | Prioridad | Complejidad |
|---|---|---|
| Singleton Colours + FileView (pattern 1) | ALTA | Media |
| IpcHandler por dominio (pattern 3) | ALTA | Baja |
| CustomShortcut + global binds (pattern 4) | ALTA | Baja |
| DrawerVisibilities por pantalla (pattern 5) | ALTA | Media |
| Anim type system M3 (pattern 6) | Media | Media |
| StyledRect con CAnim built-in (pattern 7) | Media | Baja |
| Variants para per-screen (pattern 2) | ALTA | Baja |
| Loader asynchronous (pattern 9) | Media | Baja |
| PersistentProperties para estado (pattern 12) | Media | Baja |
| Hover/drag routing single MouseArea (pattern 11) | Baja | Alta |
| StateLayer ripple M3 (pattern 8) | Baja | Alta |

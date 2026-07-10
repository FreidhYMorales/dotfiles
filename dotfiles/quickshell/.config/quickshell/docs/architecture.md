# Arquitectura general

## Árbol de módulos en shell.qml

```
ShellRoot
├── NotificationServer          ← daemon DBus; DEBE vivir aquí (no en un panel)
├── Bar {}                      ← barra superior, multi-monitor
├── Launcher {}                 ← app launcher, bottom-center
├── Dashboard {}                ← panel control, lado derecho
│
│   ── pendiente ──
├── NotificationPanel {}        ← módulo completo, falta agregarlo
│   ── phase 4 ──
├── VolumePopout {}
├── BluetoothPanel {}
├── NetworkPanel {}
└── Osd {}
│   ── phase 5 ──
└── Lock {}
```

---

## Patrón de paneles

Todos los paneles siguen exactamente la misma estructura:

```qml
// PanelWrapper.qml
Variants {
    model: Quickshell.screens          // una instancia por monitor

    delegate: Scope {
        required property ShellScreen modelData

        PanelWindow {
            screen:  modelData
            color:   "transparent"

            // Solo visible en el monitor enfocado + durante animación
            visible: content.open &&
                     modelData.name === (Hyprland.focusedMonitor?.name ?? "")

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Dismiss al click fuera del contenido
            MouseArea { anchors.fill: parent; z: 0; onClicked: Visibilities.toggle("panel") }

            PanelContent { id: content; anchors.fill: parent; z: 1 }
        }
    }
}
```

Patrones fijos:
- **`z: 0`** para el dismiss area, **`z: 1`** para el contenido — el click pasa al dismiss solo si no lo captura el contenido
- **Monitor enfocado**: `Hyprland.focusedMonitor?.name ?? ""` — los paneles nunca aparecen en el monitor incorrecto
- **`WlrLayer.Overlay`**: paneles flotan sobre el escritorio sin reservar espacio
- **`exclusiveZone: -1`**: el panel puede superponerse a la barra

### Animación estándar de slide

```qml
// Slide in desde la derecha + fade
ParallelAnimation {
    id: slideIn
    NumberAnimation { target: panel; property: "x"; from: root.width; to: 0; duration: 320; easing.type: Easing.OutCubic }
    NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }
}

// Slide out hacia la derecha + fade
ParallelAnimation {
    id: slideOut
    NumberAnimation { target: panel; property: "x"; from: 0; to: root.width; duration: 280; easing.type: Easing.InCubic }
    NumberAnimation { target: panel; property: "opacity"; from: 1; to: 0; duration: 240; easing.type: Easing.InCubic }
    onFinished: root.open = false   // ← deja de renderizar al terminar
}
```

El `Rectangle#panel` arranca en `x: root.width` (fuera de pantalla a la derecha).  
`open: bool` controla la visibilidad del `PanelWindow` entero.

---

## Sistema de visibilidades

`Visibilities.qml` (Singleton) — mutex de paneles: abrir uno cierra todos los demás.

```qml
// Uso desde cualquier widget del bar:
MouseArea { onClicked: Visibilities.toggle("dashboard") }

// Cerrar todo (ej: al cambiar de workspace)
Visibilities.closeAll()
```

Paneles registrados: `launcher`, `dashboard`, `calendar`, `notifications`.  
Al agregar un panel nuevo, agregar su bool a `Visibilities` y al array `panels` en `toggle()`.

---

## Sistema de colores

```qml
// Colours.qml lee colors.json con watchChanges: true
// Hot-reload automático cuando matugen regenera la paleta

// Uso:
color: Colours.m3primary
color: Qt.alpha(Colours.m3surfaceContainerHigh, 0.6)
Behavior on color { CAnim {} }   // siempre animar cambios de color
```

Todos los elementos deben tener `Behavior on color { CAnim {} }` para el hot-reload suave.  
Los tokens siguen la convención Material 3: `m3{role}`, `m3on{role}`, `m3{role}Container`, etc.

---

## IPC con Hyprland

La bar usa `Quickshell.Hyprland` para leer workspaces y monitor activo:
```qml
Hyprland.focusedMonitor?.activeWorkspace?.id   // workspace activo
Hyprland.workspaces                             // lista de workspaces con ventanas
Hyprland.focusedMonitor?.name                  // nombre del monitor activo
```

Para ejecutar comandos de Hyprland:
```qml
Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "2"])
```

---

## Estructura de imports en cada módulo

```qml
import Quickshell
import Quickshell.Wayland       // PanelWindow, WlrLayershell
import Quickshell.Hyprland      // Hyprland, focusedMonitor
import QtQuick
import QtQuick.Controls         // ScrollView (solo donde se necesite)
import "../../services"         // Colours, Time, Battery, Audio, Mpris, etc.
import "../../components"       // CAnim, Anim, StyledRect
```

Los servicios se importan con la ruta relativa — son singletons, no se instancian.

---

## Convenciones de animación

| Tipo | Componente | Duración | Easing |
|---|---|---|---|
| Color | `CAnim {}` | 200ms | Default |
| Entrada de panel | slideIn | 320ms | OutCubic |
| Salida de panel | slideOut | 280ms | InCubic |
| Expand/collapse | `NumberAnimation` | 200ms | OutCubic |
| Workspace dot | `NumberAnimation` | 120ms | InOutCubic |
| Launcher open | SequentialAnimation | ~1400ms total | por stage |

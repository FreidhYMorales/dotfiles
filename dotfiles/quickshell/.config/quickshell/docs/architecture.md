# Arquitectura general

## Árbol de módulos en shell.qml

```
ShellRoot
├── NotificationServer          ← daemon DBus; DEBE vivir aquí (no en un panel)
├── Background {}                ← wallpaper propio (reemplaza hyprpaper como capa activa)
├── Bar {}                       ← barra superior, multi-monitor
├── Launcher {}                  ← app launcher, bottom-center
├── Dashboard {}                 ← panel control, lado derecho
├── CalendarPopout {}             ← popout de calendario (ClockWidget)
├── Osd {}                        ← OSD de volumen + brillo
├── BatteryProfileOsd {}          ← selector de perfil de energía + caffeine
├── TrayMenuOsd {}                ← menú contextual de íconos de bandeja (BgAppsWidget)
├── RecorderModeOsd {}            ← selector de modo de grabación (screen/region/window)
├── PowerMenuOsd {}                ← menú de power (lock/logout/reboot/shutdown)
├── NotifToast {}                  ← toasts de notificaciones entrantes
├── NotificationPanel {}           ← panel completo de notificaciones/calendario/clima
├── ScreensaverPreview {}          ← preview en vivo del salvapantallas (launcher `>screensaver`)
└── Lock {}                        ← lockscreen, port visual del theme SDDM "silent"
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

Paneles registrados: `launcher`, `dashboard`, `calendar`, `notifications`, `volume`, `batteryProfile`, `notifToast`, `silentMode`, `trayMenu`, `recorderModeOsd`, `powerMenu`, `screensaverPreview`.  
Al agregar un panel nuevo, agregar su bool a `Visibilities` y al array `panels` en `toggle()`.

⚠️ `screensaverPreview` es la excepción: vive en `Visibilities` pero NO entra al array `panels` de `toggle()` ni a `closeAll()` — no es mutuamente excluyente con el launcher (el botón de preview del panel `>screensaver` lo muestra ENCIMA del launcher todavía abierto), así que los callers lo setean directamente en vez de pasar por `toggle()`.

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

### Paletas per-monitor

Además del singleton global (`Colours.m3*` / `Colours.palette`), `Colours.qml` mantiene overrides de paleta por monitor en `Colours.palettes` (keyed por `ShellScreen.name`), usados cuando cada monitor tiene su propio wallpaper/tema:

```qml
// Colours.paletteFor(screenName) devuelve el override del monitor si existe,
// si no cae al Colours.palette global — ambos exponen las mismas keys m3*,
// así que el acceso es idéntico en los dos casos.
readonly property var colors: Colours.paletteFor(root.screenName)

color: Qt.alpha(colors.m3surfaceContainerHigh, 0.6)
```

`BarContent.qml` es el consumidor principal: resuelve `root.colors` una vez por monitor y lo pasa a todos los widgets vía la prop `colors`. También expone `Colours.mid(colorA, colorB)` — punto medio RGB plano entre dos colores, usado para bordes que necesitan quedar tonalmente entre un relleno y el fondo sobre el que está (ej. el borde 1px de las píldoras de la bar).

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
Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({workspace=2})"])
```

⚠️ **Bridge Lua**: este Hyprland enruta TODOS los dispatchers por un puente Lua (`hl.dsp.*`) — los nombres de dispatcher planos (`"workspace", "2"`, `"exit"`, etc.) están muertos en esta build, `Hyprland.dispatch()` incluido. El patrón real siempre es `hyprctl dispatch "hl.dsp.<algo>(...)"` vía `Quickshell.execDetached`. Ver `modules/bar/WorkspacesWidget.qml` (`hl.dsp.focus({workspace=N})` en el click de un workspace) y el mismo patrón para logout/exit en `modules/dashboard/ProfileSection.qml`, `modules/dashboard/SessionSection.qml` y `modules/powermenu/PowerMenuOsd.qml` (`hl.dsp.exit()`).

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

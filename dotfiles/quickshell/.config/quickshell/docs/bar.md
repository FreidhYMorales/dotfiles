# Bar (`modules/bar/`)

Barra horizontal superior, flotante. Multi-monitor via `Variants { model: Quickshell.screens }`.

---

## `Bar.qml`

```
PanelWindow
  WlrLayershell.layer:         WlrLayer.Top
  WlrLayershell.exclusiveZone: 44        ← reserva 44px arriba para que las ventanas no se solapen
  anchors: top + left + right
  margins: top 8 / left 8 / right 8
  implicitHeight: 36
```

Una instancia por monitor. El `PanelWindow` es transparente — el fondo lo pinta `BarContent`.

---

## `BarContent.qml`

Fondo: `Rectangle { radius: 10; color: Qt.alpha(Colours.m3surfaceContainer, 0.92) }`.

**Layout:**

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  [Launcher] [Workspaces]          [Clock]       [BgApps][CPU][RAM][Recorder][Vol][Bat][BT][WiFi][Notif][Dashboard]  │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
  anchors.left                    anchors.centerIn              anchors.right
```

`BgAppsWidget`, `CpuWidget`, `RamWidget` y `RecorderWidget` van sueltos (sin
píldora propia) en la fila derecha; `VolumeWidget`, `BatteryWidget`,
`BluetoothWidget`, `WifiWidget`, `NotificationButton` y `DashboardButton`
comparten una segunda píldora (`rightPill`) dentro de esa misma fila. Ver
`BarContent.qml` para el detalle exacto de anidamiento.

- Fila izquierda: `Row { anchors { left; leftMargin: 8 }; spacing: 4 }`
- Centro: `ClockWidget { anchors.centerIn: parent }`
- Fila derecha: `Row { anchors { right; rightMargin: 8 }; spacing: 4 }`

⚠️ **Discrepancia con visión**: `CpuWidget` y `RamWidget` están incluidos pero no estaban en el plan original. Ver [roadmap.md](./roadmap.md).

---

## Widgets — referencia completa

### `LauncherButton`
```
Tamaño:    26×26
Acción:    Visibilities.toggle("launcher")
Visual:    ícono  (Arch logo), hover → m3primaryContainer
```

### `WorkspacesWidget`
```
Tamaño:    dinámico (dots)
Fuente:    Hyprland.focusedMonitor + Hyprland.workspaces
```

Muestra workspaces del 1 hasta el máximo activo u ocupado.  
Por cada workspace:
- `●` si activo (m3primary, 34px, ancho 28px)
- `●` si ocupado pero no activo (m3onSurfaceVariant, 26px, ancho 22px)
- `○` si vacío (m3onSurface 30% alpha, 26px, ancho 22px)

Animaciones:
```qml
Behavior on implicitWidth { NumberAnimation { duration: 120; easing: InOutCubic } }
Behavior on font.pixelSize { NumberAnimation { duration: 120; easing: InOutCubic } }
```

Click: `hyprctl dispatch workspace <n>`.

### `ClockWidget`
```
Tamaño:    dinámico (texto + 20px padding)
Visual:    pill radius:7, m3surfaceContainerHigh
Texto:     Time.date + "  |  " + Time.timeFull
           ej: "Wed 25 Jun  |  14:35:07"
Interacción: ninguna todavía
```

⚠️ La visión planea que el click abra un calendario debajo. Pendiente.

### `BgAppsWidget`
```
Tamaño:    26px colapsado → dinámico expandido
Trigger:   HoverHandler (hover para expandir)
Fuente:    hyprctl clients -j (refresco cada 3s)
```

Al hacer hover, la píldora expande hacia la izquierda mostrando los nombres de las clases de ventanas activas (primeras 8 letras, capitalizadas). Layout `Qt.RightToLeft`.

Animación:
```qml
implicitWidth: hov.containsMouse ? innerRow.implicitWidth + 16 : 26
Behavior on implicitWidth { Anim { type: Anim.Enter } }
```

### `CpuWidget`
```
Tamaño:    dinámico (ícono + % + 16px padding)
Visual:    pill radius:7, m3surfaceContainerHigh
Texto:     SysInfo.cpu + "%" — rojo (m3error) si > 80%
```

⚠️ No estaba en la visión original. Decidir si se conserva o elimina.

### `RamWidget`
```
Tamaño:    dinámico (ícono + % + 16px padding)
Visual:    igual que CpuWidget
Texto:     SysInfo.ram + "%" — rojo si > 85%
```

⚠️ No estaba en la visión original. Decidir si se conserva o elimina.

### `VolumeWidget`
```
Tamaño:    dinámico
Visual:    pill radius:7
Ícono:     󰖁 muted / 󰕾 >66% / 󰖀 >33% / 󰕿 ≤33%
Color:     gris (m3onSurfaceVariant) si muted, normal si no
Interacción: ninguna todavía (VolumePopout pendiente)
```

### `BatteryWidget`
```
Tamaño:    dinámico
Ícono:     󰂄 cargando / 󰁹 >80% / 󰂀 >50% / 󰁾 >20% / 󰁺 bajo
Color:     rojo (m3error) si < 20% sin cargar
Interacción: ninguna (solo display)
```

### `BluetoothWidget`
```
Estado:    STUB — solo ícono 󰂯 fijo
Tamaño:    26×26
Pendiente: conectar a servicio BT (Phase 4)
```

### `WifiWidget`
```
Estado:    STUB — solo ícono 󰤨 fijo
Tamaño:    26×26
Pendiente: conectar a NetworkManager (Phase 4)
```

### `DashboardButton`
```
Acción:    Visibilities.toggle("dashboard")
Ícono:     󰊓
Hover:     m3secondaryContainer
Badge:     punto 8×8 (m3tertiary) visible si NotifStore.unread > 0
```

### `NotificationButton`
```
Tamaño:    26×26
Acción:    Visibilities.toggle("notifications")
Ícono:     󰂛 modo silencioso / 󰂚 con notifs / 󰂜 sin notifs
Hover:     m3tertiaryContainer
Badge:     igual que DashboardButton
```

### `RecorderWidget`
```
Tamaño:    dinámico (ícono [+ tiempo transcurrido] + 16px padding)
Visual:    pill, borde 1px (mismo criterio que las demás píldoras de la bar)
Ícono:     󰻃 — rojo (m3error) mientras Recorder.recording, normal si no
Texto:     mm:ss transcurrido, solo visible mientras graba
Click izq: toggle start/stop de una grabación de pantalla completa (acceso rápido)
Click der: abre RecorderModeOsd (solo si no está grabando) para elegir screen/region/window
```

Fuente: `services/Recorder.qml` — ver `recorder.md` en la raíz del proyecto para la arquitectura completa (gpu-screen-recorder, slurp para region/window, por qué SIGINT y no `running = false`).

### `CalendarCard`
```
Estado:    Contenido reutilizable (Column) — usado por CalendarPopout Y por notifications/CalendarTab.qml
Contiene:  header mes/año con prev/next (HoverHandler + MouseArea propios), fila de labels Mon-Sun, grid de días (Repeater sobre buildDays())
Hoy:       círculo m3primary detrás del número
```

Mismo componente reutilizado en dos lugares — la card en sí no sabe nada de `Visibilities`, solo expone `_month`/`_year` y las funciones de navegación; quien la envuelve decide cuándo mostrarla.

### `CalendarPopout`
```
Tipo:      Variants { model: Quickshell.screens } → PanelWindow por monitor (WlrLayer.Overlay)
Trigger:   Visibilities.calendar (vía ClockWidget)
Visual:    "orejas" cóncavas (Shape + PathArc) + card con CalendarCard adentro
Posición:  anchors top/left/right, margins.top: 43 (debajo de la bar), centrado horizontal
Animación: y desliza con BezierSpline (350ms) al mostrar/ocultar; hide con Timer de 400ms de gracia
```

Mismo patrón visual ("ears + card" con `Shape`/`PathArc` cóncavo) que `TrayMenuOsd`, `BatteryProfileOsd` y `RecorderModeOsd` — solo cambia el contenido interior y el ancho/alto del card.

### `Osd`
```
Tipo:      Variants { model: Quickshell.screens } → PanelWindow por monitor (WlrLayer.Overlay)
Trigger:   Visibilities.volume (volumen) / Brightness.currentChanged (brillo) — dos cards independientes en la misma ventana
Visual:    card con slider (thumb = ícono), aparece centrado sobre VolumeWidget o BatteryWidget según volumeBarCenterX/batteryBarCenterX
Auto-hide: Timer de 2000ms tras el último cambio; se reinicia con cada nuevo evento; se pausa con HoverHandler mientras el mouse está encima
Teclado:   Keys.onEscapePressed cierra ambos OSDs de inmediato
```

Único popout que reacciona a DOS triggers distintos (volumen y brillo) en la misma `PanelWindow`, cada uno con su propio par de "orejas" y su propio card.

### `BatteryProfileOsd`
```
Tipo:      Variants { model: Quickshell.screens } → PanelWindow por monitor (WlrLayer.Overlay)
Trigger:   Visibilities.batteryProfile
Visual:    píldora segmentada (power-saver / balanced / performance) con indicador deslizante + botón de caffeine (taza llena/vacía) al lado
Acción:    BatteryProfile.set(profile) por segmento; IdleManager.caffeineMode toggle en el botón de taza
Posición:  centrado sobre batteryBarCenterX (expuesto por BarContent.qml)
```

### `TrayMenuOsd`
```
Tipo:      Variants { model: Quickshell.screens } → PanelWindow por monitor (WlrLayer.Overlay)
Trigger:   Visibilities.trayMenu (click derecho en un ícono de BgAppsWidget)
Contenido: QsMenuOpener sobre Visibilities.trayMenuTarget?.menu — el contenido viene del propio DBusMenu del tray item, no de este proyecto
Ancho:     dinámico, calculado con FontMetrics.advanceWidth() sobre la entrada más larga (mín 120px, máx 320px)
Entradas:  checkbox (✓ prefijo) y separadores soportados; hover con HoverHandler + fondo m3surfaceContainerHigh
```

### `RecorderModeOsd`
```
Tipo:      Variants { model: Quickshell.screens } → PanelWindow por monitor (WlrLayer.Overlay)
Trigger:   Visibilities.recorderModeOsd (click derecho en RecorderWidget, solo si no está grabando)
Visual:    píldora segmentada de 3 acciones (screen 󰍹 / region 󱣵 / window 󱣴), cada click es una acción one-shot, no un selector persistente
Feedback:  flash breve (150ms, fondo m3primary) en el segmento clickeado antes de cerrar el OSD
Acción:    Recorder.startScreen() / startRegion() / startWindow() según el segmento
```

A diferencia de `BatteryProfileOsd` (selector con estado "activo" persistente e indicador deslizante), acá no hay estado que sincronizar — cada segmento dispara una acción y el OSD se cierra solo.

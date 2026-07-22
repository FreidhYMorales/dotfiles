# Panel de Notificaciones (`modules/notifications/`)

Panel simple de notificaciones (ya no tiene tabs de calendario/clima — ver nota
al final de este doc). Lado derecho, ancla top+right.

---

## `NotificationPanel.qml`

Registrado en `shell.qml` (`NotificationPanel {}`) — activo.

```
WlrLayershell.layer:         WlrLayer.Overlay
WlrLayershell.exclusiveZone: -1
WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
anchors: top + right
margins: top: 43 / right: 8
implicitWidth:  324
implicitHeight: 300
```

Misma lógica de dismiss que Dashboard: MouseArea z:0 cierra al click fuera.  
Solo visible en el monitor enfocado.

---

## `NotificationPanelContent.qml`

Animación: **dropdown en `y`**, no slide horizontal. El panel arranca en
`y: -height` (oculto arriba) y anima a `y: 0` al abrir (`NumberAnimation`
350ms, `BezierSpline`). Estilo toast: una `Shape` con `PathArc` dibuja una
"oreja" redondeada a la izquierda del panel (mismo `fillColor` que el panel)
que se despliega en paralelo — mismo patrón que `NotifToast.qml`. `openTimer`
(16ms) retrasa `panelOpen = true` un frame para que `PanelWindow` termine su
layout antes de que `y` sea confiable; `closeTimer` (400ms) mantiene la
ventana visible mientras corre la animación de cierre.  
Fondo: `Colours.m3surfaceContainer` (con `topLeftRadius`/`topRightRadius: 0`
para calzar con la "oreja").

### Estructura real

```
Rectangle #panel
├── Item #header (height: 44)
│     ├── Text "Notifications"
│     ├── Row (derecha)
│     │     ├── Ícono 󰂚/󰂛 (según Visibilities.silentMode)
│     │     └── Toggle "silent mode" → Visibilities.silentMode
│     └── Separador 1px al fondo
└── NotificationsTab (anchors: debajo del header, resto del panel)
```

Ya no existen `activeTab`, la tab bar de 3 pestañas, ni `CalendarTab`/`WeatherTab`
dentro de este módulo — ver nota al final del doc.

---

## `NotificationsTab.qml` ✅

### Estado vacío
```
Column (centrado)
├── Ícono 󰂜 (36px, m3onSurfaceVariant)
└── Text "No notifications"
```

### Estado con notificaciones
```
Item
├── Text "Clear all" (top-right) → NotifStore.clear()
└── ScrollView
      └── ListView
            model: NotifStore.notifications
            delegate: NotificationItem
```

`NotifStore.notifications` es un `ListModel` — se actualiza reactivamente al recibir notificaciones.

---

## `NotificationItem.qml`

```
Item (implicitHeight: 72)
├── Rectangle hover bg (m3onSurface 6%)
├── Rectangle barra izquierda 3px (m3error, visible si urgency === 2)
└── Row
      ├── Image/Ícono app 24×24
      ├── Column
      │     ├── Text appName (9px, m3onSurfaceVariant)
      │     ├── Text summary (12px Medium, m3onSurface, ElideRight)
      │     └── Text body (11px, m3onSurfaceVariant, WordWrap, max 2 líneas)
      └── Botón × 28×28 → NotifStore.dismiss(index)
```

Urgencias: `0` low, `1` normal, `2` critical (barra roja).  
Divisor inferior oculto en el último ítem (`isLast: bool`).

---

## `NotifToast.qml`

Toast de notificación emergente, uno por pantalla (`Variants` sobre
`Quickshell.screens`), independiente del panel de arriba — es lo que aparece
cuando llega una notificación nueva mientras el panel está cerrado. Ancla
top+right con la misma "oreja" (`Shape`/`PathArc`) que `NotificationPanelContent`,
animando `y` con la misma curva (350ms `BezierSpline`). Muestra ícono/inicial
de la app, nombre, resumen (2 líneas) y body (3 líneas), con botón × para
descartar. Se auto-descarta con `dismissTimer` (usa `expireTimeout` de la
notificación, o 5000ms si no viene seteado); el hover lo pausa. Se suprime si
`Visibilities.silentMode` o `Visibilities.dashboard` están activos, y se oculta
si el dashboard se abre mientras el toast está visible. Solo se muestra en el
monitor enfocado (`win.isFocused`).

---

## Nota — `CalendarTab.qml` / `WeatherTab.qml`

Estos dos archivos siguen existiendo en `modules/notifications/`, pero **ya no
se usan desde el panel de notificaciones** — la tab bar de 3 pestañas que los
mostraba fue eliminada (ver `NotificationPanelContent.qml` arriba). Hoy se
instancian solo desde el dashboard: `modules/dashboard/DashboardContent.qml`
(`WeatherTab`) y `modules/dashboard/DashboardNotificationsSection.qml`
(`CalendarTab` + `WeatherTab`). `docs/dashboard.md` todavía no los documenta —
si se necesita el detalle de su funcionamiento (calendario mensual navegable,
fetch a `wttr.in`, etc.), por ahora hay que leer los archivos directamente o
agregarlos a `dashboard.md`.

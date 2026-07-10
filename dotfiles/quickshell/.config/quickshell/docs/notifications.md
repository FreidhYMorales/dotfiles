# Panel Notificaciones / Calendario / Clima (`modules/notifications/`)

Panel con 3 tabs. Lado derecho, 380×560px.

---

## `NotificationPanel.qml`

⚠️ **El módulo está completo pero NO está registrado en `shell.qml`.**  
Falta agregar `NotificationPanel {}` en `shell.qml` para activarlo.

```
WlrLayershell.layer:         WlrLayer.Overlay
WlrLayershell.exclusiveZone: -1
anchors: top + right
margins: top: 52 / right: 8
implicitWidth:  380
implicitHeight: 560
```

Misma lógica de dismiss que Dashboard: MouseArea z:0 cierra al click fuera.  
Solo visible en el monitor enfocado.

---

## `NotificationPanelContent.qml`

Animación: slide-in/slide-out desde la derecha (igual que Dashboard, ver [architecture.md](./architecture.md)).  
Fondo: `Qt.alpha(Colours.m3surfaceContainer, 0.97)`.

### Tab bar

```
Item (height: 44)
└── Row (centrado)
      └── Repeater (3 tabs)
            ├── Tab 0: 󰂚 Notifications
            ├── Tab 1: 󰃭 Calendar
            └── Tab 2: 󰖙 Weather
```

Tab activo: `Rectangle { color: m3primaryContainer }` + texto `m3onPrimaryContainer`.  
Tab inactivo: fondo transparente + texto `m3onSurfaceVariant`.  
Separador de 1px al fondo del tab bar.

### Área de contenido

```qml
NotificationsTab { visible: activeTab === 0 }
CalendarTab      { visible: activeTab === 1 }
WeatherTab       { visible: activeTab === 2 }
```

Todos están siempre instanciados — `visible: false` no los destruye (eficiencia aceptable para 3 tabs).

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

## `CalendarTab.qml` ✅

Calendario mensual navegable. Se sincroniza con `Time.now` para destacar el día actual.

### Estructura
```
Column
├── Header (height: 36)
│     ├── Botón ← (mes anterior)
│     ├── Text "Month Year" (centrado)
│     └── Botón → (mes siguiente)
├── Row días de la semana (Mon–Sun)
└── Grid 7 columnas (días del mes)
```

### Lógica del grid

```qml
function buildDays(year, month) {
    // offset lunes-based: (firstDay + 6) % 7
    // rellena con días del mes anterior y siguiente para completar semanas
    return [{ day: int, thisMonth: bool }]
}
```

Hoy: círculo `m3primary` 24×24 con texto `m3onPrimary`.  
Días de otros meses: texto al 35% de opacidad.

### Navegación

```qml
// Prev month
root._month--
if (root._month < 0) { root._month = 11; root._year-- }

// Next month
root._month++
if (root._month > 11) { root._month = 0; root._year++ }
```

La fecha actual se sincroniza con `Time.now` via `Connections { target: Time; function onNowChanged() }` — actualiza solo si cambia el día.

---

## `WeatherTab.qml` ✅

Datos de `wttr.in` (curl). Refresco cada **30 minutos**.

### Fetch

```qml
Process {
    command: ["curl", "-s", "--max-time", "5", "wttr.in/?format=j1"]
}
```

JSON response: `current_condition[0]` + `nearest_area[0]`.

### Campos parseados

| Propiedad | Fuente wttr |
|---|---|
| `_temp` | `temp_C + "°C"` |
| `_desc` | `weatherDesc[0].value` |
| `_location` | `nearest_area[0].areaName[0].value` |
| `_humidity` | `humidity + "%"` |
| `_wind` | `windspeedKmph + " km/h"` |
| `_weatherIcon` | mapeado desde `weatherCode` → Nerd Font |

### Íconos por código wttr

| Código | Condición | Ícono |
|---|---|---|
| 113 | Soleado | 󰖙 |
| 116, 119 | Parcialmente nublado | 󰖕 |
| 122, 143 | Nublado / neblina | 󰖑 |
| 176–296 | Lluvia | 󰖗 |
| 200–202, 386–392 | Tormenta | 󰖓 |
| 227, 230, 323–371 | Nieve | 󰖘 |

### Layout de datos
```
Column (centrado)
├── Row: ícono grande (40px, m3primary) + temperatura (32px Medium)
├── Text descripción (13px)
├── Text ubicación (11px, m3onSurfaceVariant)
└── Row
      ├── 󰖋 humedad
      └── 󰖝 viento
```

Estados: loading ("Loading..."), error ("Weather unavailable"), datos (layout completo).

⚠️ Requiere conexión a internet. Sin internet: `_error = true` → "Weather unavailable".  
⚠️ `wttr.in` puede tener latencia variable. `--max-time 5` evita cuelgues largos.

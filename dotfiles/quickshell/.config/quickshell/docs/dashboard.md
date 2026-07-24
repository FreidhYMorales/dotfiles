# Dashboard (`modules/dashboard/`)

Panel de control principal. Lado derecho, 340px de ancho.

---

## `Dashboard.qml`

```
WlrLayershell.layer:         WlrLayer.Overlay
WlrLayershell.exclusiveZone: -1             ← puede solapar la bar
anchors:  top + right + bottom
margins:  top: 52   ← bar (44) + espacio (8) para quedar justo debajo
          right: 8 / bottom: 8
width:    340px
```

Solo visible en el monitor enfocado. Dismiss al click fuera del contenido (MouseArea z:0).  
`DashboardContent` maneja su propio `open: bool` para controlar la visibilidad del PanelWindow durante la animación.

---

## `DashboardContent.qml`

Panel de perfil (`ProfileSection`, ancla arriba, drop-down propio) + `ScrollView` vertical debajo, sin scrollbar (`ScrollBar.vertical.policy: ScrollBar.AlwaysOff`), con las cápsulas que sí scrollean.

```
┌─────────────────────────────┐
│  ProfileSection              │  panel fijo arriba (Capsule, color m3surfaceContainer liso)
├─────────────────────────────┤
│  Notificación activa          │  Cápsula 0 — solo si hay una (height 0 si no)
├─────────────────────────────┤
│  WeatherTab                  │  Cápsula 1
├─────────────────────────────┤
│  BatterySection               │  Cápsula 2
│  ───────────────────         │  (separador 1px)
│  PerformanceSection           │
├─────────────────────────────┤
│  MediaSection                 │  Cápsula 3 (visible solo si Mpris.hasPlayer)
└─────────────────────────────┘
```

Las 5 (panel de perfil + 4 cápsulas) usan `components/Capsule.qml` — mismo `radius`/borde/`Behavior on color`, cada una solo pisa `color`/tamaño/animación de entrada según haga falta. Antes eran 5 `Rectangle` con las mismas 4 líneas de estilo copiadas.

⚠️ `DashboardNotificationsSection.qml` y `SessionSection.qml` están registrados en `qmldir` pero **no los instancia nadie** — código muerto, no confundir con las secciones reales de arriba.

---

## `ProfileSection.qml`

Avatar del usuario + nombre + uptime + fila de power (Suspend/Lock/Logout/Reboot/Shutdown, estilo `PowerMenuButton`: solo ícono, sin fondo, hover = `scale: 1.35` + color `m3primary`). La fila de power no tiene su propio fondo/borde — es un `Item` con un divisor de 1px arriba (`Qt.alpha(Colours.m3outlineVariant, 0.25)`) para separarla del resto, terminal-alike en vez de una píldora anidada.

---

## `BatterySection.qml`

Porcentaje + `SegmentedMeter` (10 bloques discretos, el bloque de frontera interpola alpha según el resto — ver `components.md`) en vez de la barra continua anterior. `fillColor`: `m3primary` si está cargando, `m3error` si `percentage < 20`, si no `m3secondary`.

---

## `PerformanceSection.qml`

Filas (no grilla de círculos) — CPU, RAM, GPU (solo si `SysInfo.hasGpu`), Disk. Cada fila es un `BlockMetric` (ícono+label a la izquierda, `SegmentedMeter` en el medio, `valor%` a la derecha, divisor de 1px abajo excepto la última). Reemplazó el `CircleMetric` anterior (arco dibujado en `Canvas`) — sin fondo por fila, separadas por divisores en vez de cajas con borde propio.

| Métrica | Servicio | Color (`arcColor` → `fillColor` del `SegmentedMeter`) |
|---|---|---|
| CPU | `SysInfo.cpu` | `m3primary` |
| RAM | `SysInfo.ram` | `m3secondary` |
| GPU | `SysInfo.gpu` (solo si `hasGpu`) | `m3tertiary` |
| Disk | `SysInfo.disk` | `m3tertiary` |

---

## `MediaSection.qml`

El componente más complejo del dashboard. Controla el reproductor MPRIS activo.

**Propiedades internas:**
```qml
property bool _expanded: false   // estado del selector de player
property real localPos:  0       // posición local (sync con Mpris.position + timer)
```

**Estructura (Column con `spacing: 8`, `padding: 8px`):**

### 1. Arte + metadata
```
Row (spacing: 12)
├── Rectangle 56×56 (radius: 8, clip: true)
│     ├── Image (artUrl, PreserveAspectCrop) — visible si artUrl !== ""
│     └── Text "󰝚" — fallback si no hay arte
└── Column
      ├── Text título (13px Medium, ElideRight)
      └── Text artista (11px, ElideRight)
```

### 2. Progress bar + tiempo
Solo visible si `Mpris.length > 0`.

```
Column (spacing: 4)
├── Item (height: 4)
│     ├── Rectangle track: Qt.alpha(m3primary, 0.2)  ← muestra la duración total
│     └── Rectangle fill:  m3primary                  ← progreso actual
│           width animado: Behavior on width { NumberAnimation { duration: 800; Linear } }
└── Row (posición izquierda / duración derecha)
      ├── Text posición: _fmtTime(localPos)
      └── Text duración: _fmtTime(Mpris.length)
```

Formato tiempo: `_fmtTime(secs)` → `"m:ss"` (ej: `"3:42"`).

**Sincronización de posición:**
- `localPos` se actualiza desde `Mpris.position` via `Connections`
- Timer 1s (running: `Mpris.playing`) incrementa `localPos` en 1 por tick
- Al cambiar de pista o player, `_syncPos()` resetea `localPos`

### 3. Controles + selector

**Controles (izquierda):**
```
Row (spacing: 4)
├── Prev 32×32  — habilitado si Mpris.canPrev, llama Mpris.previous()
├── Play/Pause 32×32  — ícono 󰏤/󰐊 según Mpris.playing
└── Next 32×32  — habilitado si Mpris.canNext, llama Mpris.next()
```

**Selector horizontal (derecha):**

La píldora es un `Item` anclado a la derecha que se expande hacia la izquierda.

```
selectorItem (right-anchored, height: 28)
├── Rectangle background (radius: 14, color: Qt.alpha(m3surfaceContainerLow, 0.8))
├── listClip (Item con clip: true)
│     └── ListView (horizontal, SnapToItem)
│           model: Mpris.otherCount
│           delegate: Item (width via TextMetrics)
│               ├── Rectangle separador (1px, visible si index > 0)
│               ├── Text nombre del player
│               └── MouseArea → selectPlayer + collapse
│           └── Rectangle indicador ‹ (visible si contentX > 0)
├── Rectangle divisor (1px, entre lista y handle)
└── handleArea (right-anchored)
      ├── Text nombre player activo
      ├── Text flecha ◂/▸
      └── MouseArea → toggle _expanded
```

**Cálculo de ancho:**
```qml
readonly property real _naturalW: playerList.contentWidth      // suma real de chips
readonly property real _maxW: parent.width - handleArea.width - ctrlRow.width - 8
readonly property real _listW: Math.min(_naturalW, _maxW)      // nunca tapa los controles

width: handleArea.width + (root._expanded && Mpris.playerCount > 1 ? _listW : 0)
Behavior on width { NumberAnimation { duration: 200; easing: OutCubic } }
```

**Ancho de chips via TextMetrics:**
```qml
// Evita forward reference (width: childId.implicitWidth falla en delegates)
TextMetrics {
    id: tm
    text: Mpris.playerDisplayName(chip.entry.mp ?? null)
    font.family: Style.fontFamily
    font.pixelSize: 11
}
width: tm.advanceWidth + 24
```

**Scroll:**
- `interactive: selectorItem._naturalW > selectorItem._maxW`
- `WheelHandler` → traduce rueda vertical a `contentX`
- Al colapsar: `playerList.contentX = 0`
- Indicador `‹`: `visible: playerList.contentX > 0`

---

## `DashboardNotificationsSection.qml`

Preview de notificaciones dentro del dashboard.  
(Distinto de `NotificationPanel` — este es el resumen, no el panel completo.)

---

## Altura del dashboard

Cada cápsula usa `height: section.implicitHeight`.  
`MediaSection` se oculta completamente (`visible: Mpris.hasPlayer`) — `Column.implicitHeight` lo excluye automáticamente cuando `visible: false`.

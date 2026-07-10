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

`ScrollView` vertical, sin scrollbar (`ScrollBar.vertical.policy: ScrollBar.AlwaysOff`).  
Padding: `leftMargin: 8; rightMargin: 8`. `contentWidth: availableWidth`.

**4 cápsulas apiladas** (`spacing: 8`, `topPadding/bottomPadding: 10`):

```
┌─────────────────────────────┐
│  ProfileSection             │  Cápsula 1
├─────────────────────────────┤
│  DashboardNotificationsSection │  Cápsula 2
├─────────────────────────────┤
│  BatterySection             │  Cápsula 3
│  ───────────────────        │  (separador 1px)
│  PerformanceSection         │
├─────────────────────────────┤
│  MediaSection               │  Cápsula 4 (visible solo si Mpris.hasPlayer)
└─────────────────────────────┘
```

Cada cápsula: `Rectangle { radius: 12; color: Colours.m3surfaceContainerHigh }`.  
La altura de cada cápsula sigue el `implicitHeight` de su sección.

---

## `ProfileSection.qml`

Avatar del usuario + nombre + uptime.  
(Detalles de implementación a completar cuando se revise el archivo.)

---

## `SessionSection.qml`

Botones de sesión: power, reboot, suspend, lock, logout.  
(Archivo existe, detalles a documentar.)

---

## `BatterySection.qml`

Información detallada de la batería: porcentaje, estado de carga, salud, tiempo restante.  
Usa `Battery.percentage`, `Battery.charging`, `Battery.health`, `Battery.timeStr`.

---

## `PerformanceSection.qml`

Row de `CircleMetric` para CPU, RAM, GPU (opcional), Disk.

**Componente `CircleMetric` (inline):**
```
implicitHeight: 78px
├── Canvas 50×50 (arco de progreso)
│     ├── Background track: Qt.rgba(color, 0.2)
│     └── Arc de progreso: color sólido, lineCap "round"
├── Texto ícono centrado en el canvas
└── Texto "LABEL VALUE%" debajo del canvas (topMargin: 5)
```

```qml
// Propiedades:
property int    value:    0        // 0-100
property string icon:     ""       // Nerd Font codepoint
property string label:    ""       // "CPU", "RAM", etc.
property color  arcColor: Colours.m3primary
```

⚠️ Canvas requiere `requestPaint()` en `onValueChanged` y `onArcColorChanged`.

**Distribución de anchos:**
```qml
readonly property int count: SysInfo.hasGpu ? 4 : 3
readonly property int itemW: Math.floor((width - (count - 1) * spacing) / count)
```

**Métricas y colores:**

| Métrica | Servicio | Color |
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
    font.family: "Iosevka Term Nerd Font"
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

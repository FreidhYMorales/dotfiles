# Quickshell Animation Patterns

## Core pattern: slide on Y, not grow on height

All panel/card open-close animations animate `y` (vertical slide), NOT `height`.

### Why not height?

Animating `height` on a `Rectangle` with `radius` causes a visible shape change:
- When `height < radius` → card looks like a pill / semicircle
- When `height > radius` → straight side walls appear abruptly
- Result: curved → square visual artifact during animation

### The fix

Keep `height` fixed at the card's final size. Animate `y` instead:

```qml
Rectangle {
    id: card
    height: 56                                    // fixed — never animated
    y:      condition ? 0 : -56                   // slides from behind the bar
    Behavior on y {
        NumberAnimation {
            duration:           350
            easing.type:        Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
        }
    }
    radius:         12
    topLeftRadius:  0   // square — connects flush to bar bottom
    topRightRadius: 0   // square — connects flush to bar bottom
}
```

The bar covers the card at `y: -height`. When `condition` becomes true, the card
slides out from under the bar. No shape change — corners are always in their final form.

---

## Spring bezier

Every animation uses the same curve:

```qml
easing.type:        Easing.BezierSpline
easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
duration:           350   // ms
```

This is a spring: starts fast, overshoots slightly, settles. Use `InCubic` (240ms)
for close animations where overshoot looks bad (e.g. going to 0).

---

## Ears (concave corner fills)

Ears are `Shape + ShapePath + PathArc` elements that fill the concave corner between
the bar and the card's top edge. They use the same y-slide pattern:

```qml
Shape {
    x:      card.x - radius   // left of card
    y:      condition ? 0 : -radius
    width:  radius
    height: radius
    Behavior on y { /* same spring */ }
    ShapePath {
        startX: 0; startY: 0
        PathArc  { x: r; y: r; radiusX: r; radiusY: r; direction: PathArc.Clockwise }
        PathLine { x: r; y: 0 }
    }
}
```

**Do NOT use `clip: true` + animate `height`** on a Shape. The clip boundary is a
straight horizontal line that cuts through the arc, producing the same curved→square
artifact.

Right-side ear uses `PathArc.Counterclockwise` and starts from `startX: r; startY: 0`.

---

## PanelWindow: fixed implicitHeight

**Never bind `implicitHeight` to an animating property.**

```qml
// BAD — resizes Wayland surface every frame → jank
implicitHeight: card.height + 8

// GOOD — surface is fixed, compositor never resizes
implicitHeight: 64
```

When a PanelWindow's `implicitHeight` changes, Qt tells the Wayland compositor to
resize the surface buffer. This happens every animation frame and can cause stalls.
A fixed height keeps the surface constant — Qt only redraws internally.

Set `implicitHeight` to the maximum content size with a small buffer.

---

## Window visibility during close animation

The card animates for 350ms when closing. The window must stay visible during that time.
Use a Timer slightly longer than the animation:

```qml
// In the PanelWindow or content Item:
property bool _visible: false

Timer { id: hideTimer; interval: 400; onTriggered: win._visible = false }

// On open:
hideTimer.stop()
win._visible = true

// On close:
hideTimer.restart()   // keeps window alive for 400ms while card slides back up

visible: isFocused && win._visible
```

---

## Bar corner synchronization (notification panel)

The bar's `bottomRightRadius` must stay square while the notification panel's close
animation plays. Use a local flag + timer in BarContent:

```qml
property bool _notifCornerFlat: false

Timer {
    id: notifCornerTimer
    interval: 350  // matches panel close animation
    onTriggered: root._notifCornerFlat = false
}

Connections {
    target: Visibilities
    function onNotificationsChanged() {
        if (Visibilities.notifications) {
            notifCornerTimer.stop()
            root._notifCornerFlat = true
        } else {
            notifCornerTimer.restart()  // delay rounding until panel finishes closing
        }
    }
}

// In the bar Rectangle:
bottomRightRadius: (Visibilities.notifToast || root._notifCornerFlat) ? 0 : height / 2
```

---

## OSD card dimensions

All OSD cards use: **2px top padding, 5px bottom padding** from card edge to content.

| Card | Content height | Card height |
|------|---------------|-------------|
| Volume / Brightness slider | 28px | 35px |
| Battery profile pill | 32px | 39px |
| Calendar | `calCard.implicitHeight` | `+ 7` |

Content anchored `top: parent.top; topMargin: 2`. This places content near the bar
edge (the card's top is flush with the bar bottom), leaving visual breathing room below.

---

## Shared pill pattern for bar widgets

When grouping multiple widgets into one pill, use a `standalone: bool` property
(default `true`) on each widget. When `false`: individual background hidden,
no inner padding. A parent Rectangle provides the shared background.

```qml
// Widget (e.g. VolumeWidget.qml):
property bool standalone: true
implicitWidth: Math.max(26, row.implicitWidth) + (standalone ? 16 : 0)
Rectangle { anchors.fill: parent; visible: root.standalone; ... }

// BarContent: shared pill
Rectangle {
    id: rightPill
    height: 26; radius: height / 2
    width: pillRow.implicitWidth + 8
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Row { id: pillRow; anchors.centerIn: parent
          VolumeWidget { id: volWidget; standalone: false } ... }
}
```

The pill's `width` animates automatically when VolumeWidget or BatteryWidget expand
(their `implicitWidth` changes → `pillRow.implicitWidth` changes → `rightPill.width`
binding re-evaluates → `Behavior` intercepts and animates).

---

## OSD position tracking — reactive Binding (NOT mapToItem)

**Problem**: widgets inside a pill have `x: 0` in the Row (first item never moves
locally), so `onXChanged` never fires. `mapToItem(null, ...)` called at
`Component.onCompleted` returns `0` before the scene is laid out → OSD appears
at screen x = 8 (far left).

**Fix**: use a geometric Binding in BarContent that tracks `rightPill.width`
(which IS reactive, animates via Behavior) and `pillRow.implicitWidth`:

```qml
// In BarContent — AFTER rightPill and pillRow are declared
Binding { target: Visibilities; property: "volumeBarCenterX"
          value: root.width - rightPill.width / 2 - pillRow.implicitWidth / 2
                 + volWidget.implicitWidth / 2 }
Binding { target: Visibilities; property: "batteryBarCenterX"
          value: root.width - rightPill.width / 2 - pillRow.implicitWidth / 2
                 + volWidget.implicitWidth + batWidget.implicitWidth / 2 }
```

Derived from: `pillRow` is centered in `rightPill` (offset = `(rightPill.width - pillRow.implicitWidth) / 2`),
and `rightPill.right` is always at `root.width - 8` (rightRow rightMargin).

In the widgets, guard `updateCenterX` with `if (!standalone) return` to avoid
breaking the Binding with direct assignment.

**Binding items must be declared AFTER all referenced ids**, not before — QML
evaluates Binding values immediately on creation.

---

## Expanding Item for percent text — symmetric margins

When a widget shows a percentage inline (e.g. `VolumeWidget`, `BatteryWidget`), the text
lives inside a clipped `Item` that animates its `width`:

```qml
Item {
    width:  showPercent ? percentText.implicitWidth + 10 : 0  // 5px left + 5px right
    height: percentText.implicitHeight
    clip:   true
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Text {
        id: percentText
        anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
    }
}
```

**Both sides need margin.** `leftMargin: 5` handles gap between icon and text. The extra `+5`
in width (total `+10`) provides right breathing room vs. the next widget in the pill Row.
Using only `+5` (leftMargin only) causes the text to appear flush against the next widget.

---

## Stagger de capsules dentro de Column — clip wrapper + y slide

Cada cápsula vive en un `Item { clip: true }` que tiene la altura final de la cápsula.
La `Rectangle` interna anima `y` entre `0` (visible) y `-root.height` (oculto arriba).
`root.height` en vez de `cap.height` evita el flash inicial cuando `cap.height = 0` antes del layout.

```qml
Item { width: parent.width; height: cap.height; clip: true
    Rectangle {
        id: cap; width: parent.width; height: 116; radius: 12
        y: root._stage >= 1 ? 0 : -root.height
        Behavior on y {
            NumberAnimation {
                duration: 100; easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
            }
        }
    }
}
```

### Apertura — timers absolutos desde openTimer

Los timers de apertura (`s1`, `s2`, `s3`) arrancan simultáneamente al disparar `openTimer`.
Intervalos calculados como: `s(N) = profile_duration - 10 + (N-1) * (cap_duration + 10)`.

```qml
Timer { id: openTimer; interval: 16; onTriggered: { root.panelOpen = true; s1.restart(); s2.restart(); s3.restart() } }
Timer { id: s1; interval: 140; onTriggered: root._stage = 1 }   // profile (150ms) - 10
Timer { id: s2; interval: 250; onTriggered: root._stage = 2 }   // s1 + cap (100ms) + 10
Timer { id: s3; interval: 360; onTriggered: root._stage = 3 }   // s2 + cap (100ms) + 10
```

### Cierre — timers inversos con adaptive guard

Los timers de cierre (`cs1`–`cs4`) bajan `_stage` en orden inverso, luego ocultan el panel.
El guard `if (root._stage > N)` evita que un cierre mid-apertura suba el stage accidentalmente.

```qml
Timer { id: cs1; interval: 10;  onTriggered: { if (root._stage > 2) root._stage = 2 } }
Timer { id: cs2; interval: 120; onTriggered: { if (root._stage > 1) root._stage = 1 } }
Timer { id: cs3; interval: 230; onTriggered: { if (root._stage > 0) root._stage = 0 } }
Timer { id: cs4; interval: 340; onTriggered: root.panelOpen = false }
Timer { id: closeTimer; interval: 540; onTriggered: root.open = false }
```

Intervalos: `cs(N).interval = (N-1) * (cap_duration + 10) + 10`. `cs4 = cs3 + cap_duration + 10`. `closeTimer = cs4 + profile_duration + 50`.

### Manejo de open/close en Connections

```qml
function onDashboardChanged() {
    if (Visibilities.dashboard) {
        closeTimer.stop()
        cs1.stop(); cs2.stop(); cs3.stop(); cs4.stop()
        root.open = true; root.panelOpen = false; root._stage = 0
        openTimer.restart()
    } else {
        openTimer.stop()
        s1.stop(); s2.stop(); s3.stop()
        cs1.restart(); cs2.restart(); cs3.restart(); cs4.restart()
        closeTimer.restart()
    }
}
```

---

## Cápsula dinámica de altura variable — reveal por top (height-only)

Cuando una cápsula debe aparecer en la PRIMERA posición de un Column (pegada al panel de arriba),
usar solo `wrapper.height` para la animación — sin animar `y` en la Rectangle interna.
El contenido queda en `y: 0` siempre; el clip del wrapper la revela de arriba hacia abajo.

```qml
Item {
    id: wrapper
    width: parent.width
    height: active ? 82 : 0   // fixed height — evita coupling con implicitHeight dinámico
    clip: true
    Behavior on height {
        NumberAnimation {
            duration: 150; easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
        }
    }

    Rectangle {
        id: cap; width: parent.width; height: 82; radius: 12
        // NO y animation — always at y: 0
    }
}
```

**Por qué height-only aquí**: El Column es reactivo — cuando `wrapper.height` anima de 0 a 82px,
el Column reposiciona todos los items siguientes continuamente cada frame. Los capsules de abajo
se desplazan solos sin código extra. Si se animara `y` en la Rectangle interna a la vez, la mitad
inferior del contenido sería visible primero (el top queda oculto hasta el final de la animación).

**Cuándo usar `y`-slide en cambio**: para capsules que NO están en la primera posición del Column,
o paneles que se desligan del padre (perfil, notif panel). Ver sección anterior.

---

## Supresión de toast cuando el dashboard está abierto

Cuando un panel del dashboard ya muestra la notificación como widget integrado,
el toast de overlay debe suprimirse para evitar duplicación:

```qml
// NotifToast.qml — en onListChanged:
if (Visibilities.dashboard) return

// También: cerrar toast activo si el dashboard abre
Connections {
    target: Visibilities
    function onDashboardChanged() {
        if (Visibilities.dashboard && win.showing) {
            dismissTimer.stop()
            win.showing = false
        }
    }
}
```

El dashboard absorbe la notificación activa al abrirse checkeando `Notifs.list[0]`
con guard `_lastNotifId` para no repetir la misma notificación si el dashboard
se abre/cierra varias veces.

---

## Bar corner — sincronizar bottomRightRadius con paneles derechos

Cualquier panel anclado a la derecha que se conecta a la barra debe aplanar
`bottomRightRadius` de la barra mientras está abierto (y durante su animación de cierre):

```qml
// BarContent.qml — un flag + timer por panel
property bool _notifCornerFlat: false
property bool _dashCornerFlat:  false

Timer { id: dashCornerTimer; interval: 500; onTriggered: root._dashCornerFlat = false }

Connections {
    target: Visibilities
    function onDashboardChanged() {
        if (Visibilities.dashboard) { dashCornerTimer.stop();    root._dashCornerFlat = true }
        else                        { dashCornerTimer.restart() }
    }
}

// En el Rectangle de la barra:
bottomRightRadius: (Visibilities.notifToast || root._notifCornerFlat || root._dashCornerFlat) ? 0 : height / 2
```

---

## Lock screen — dragon.conf two-phase layout

Layout based on Silent SDDM `dragon.conf`, adapted to M3 colors.

### Phase 1 (idle) — clock center-right

```qml
Column {
    anchors { right: parent.right; rightMargin: 80; verticalCenter: parent.verticalCenter }
    spacing: -10    // slight overlap: date visually near clock bottom (dragon margin-top: -15)

    Text { text: Time.hours12 + ":" + Time.minutes; font.pixelSize: 120; font.weight: Font.Black }
    Text { text: Time.fullDate; font.pixelSize: 25; font.weight: Font.ExtraBold; color: Colours.m3primary }
}
```

No hint message (`dragon.conf: LockScreen.Message.display = false`).

### Phase 2 (active) — auth area right, 50px margin

```qml
Item {
    anchors { right: parent.right; rightMargin: 50; verticalCenter: parent.verticalCenter }
    width: 200; height: authCol.implicitHeight

    Column {
        id: authCol
        width: parent.width
        spacing: 14
        transform: Translate { x: root.shakeOffset }   // shake doesn't conflict with right anchor

        Rectangle { width: 120; height: 120; radius: 60 ... }  // avatar
        Text { font.pixelSize: 18; font.weight: Font.Bold }    // username

        Row {
            spacing: 0
            Item { width: 150; height: 36
                Rectangle { topLeftRadius: 18; bottomLeftRadius: 18; topRightRadius: 0; bottomRightRadius: 0 }
                // password dots / placeholder
            }
            Item { width: 36; height: 36
                Rectangle { topLeftRadius: 0; bottomLeftRadius: 0; topRightRadius: 18; bottomRightRadius: 18 }
                // submit arrow icon
            }
        }
    }
}
```

**Key**: `transform: Translate { x: root.shakeOffset }` — using `x:` directly conflicts with `anchors.right`.

### Background — no blur

`LockSurface.qml`: `ScreencopyView` without MultiEffect blur. Overlay opacity `0.65` compensates.

---

## Files that implement these patterns

| File | What it animates |
|------|-----------------|
| `modules/bar/Osd.qml` | volCard y, brightCard y, 4 ears y |
| `modules/bar/CalendarPopout.qml` | card y, 2 ears y |
| `modules/bar/BatteryProfileOsd.qml` | card y, 2 ears y |
| `modules/notifications/NotifToast.qml` | card y, 1 ear y |
| `modules/notifications/NotificationPanelContent.qml` | panel y, 1 ear y |
| `modules/bar/BarContent.qml` | bottomRightRadius (timer) + OSD position Bindings |
| `modules/dashboard/DashboardContent.qml` | profile y + ear y + capsule stagger (s/cs timers) + notif height |
| `modules/notifications/NotifToast.qml` | toast suprimido cuando dashboard activo |
| `modules/lock/LockAuth.qml` | two-phase UX, clock right-aligned (120px), compound pill, shake via Translate |
| `modules/lock/LockSurface.qml` | ScreencopyView sin blur, overlay 0.65 |

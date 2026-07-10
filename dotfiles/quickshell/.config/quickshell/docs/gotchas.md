# Gotchas y pitfalls conocidos

Errores reales encontrados durante el desarrollo. Leer antes de tocar servicios o delegates.

---

## Quickshell / MPRIS

### El singleton MPRIS se llama `Mpris`, no `MprisController`

```qml
// MAL:
import Quickshell.Services.Mpris
MprisController { ... }         // ReferenceError

// BIEN:
Mpris.players                   // acceso directo al singleton
```

### `MprisPlaybackStatus` no está exportado

En la build actual de Quickshell, el enum no está disponible en QML.

```qml
// MAL:
player.playbackStatus === MprisPlaybackStatus.Playing   // ReferenceError

// BIEN:
player.playbackStatus === 1    // 1 = Playing
```

### `Mpris.players` es `UntypedObjectModel`, no un array

```qml
// MAL:
Mpris.players.length     // undefined
Mpris.players.count      // undefined
Mpris.players[0]         // undefined

// BIEN:
Mpris.players.values           // JS array de players
Mpris.players.values.length    // cantidad de players
Mpris.players.values[0]        // primer player
```

### `onPlayersChanged` no existe en el singleton Mpris

```qml
// MAL:
Connections { target: Mpris; function onPlayersChanged() { ... } }

// BIEN:
Connections { target: Mpris.players; function onValuesChanged() { ... } }
```

### `property var` no trackea sub-propiedades

Binding via `property var` solo reacciona cuando el objeto entero cambia, no cuando cambia una propiedad interna.

```qml
// MAL — no se actualiza cuando cambia el título:
property var player: Mpris.players.values[0]
Text { text: player.trackTitle }   // queda estático

// BIEN — propiedades explícitas + Connections:
property string title: ""
Connections {
    target: root.player   // se rebindea cuando player cambia
    function onTrackTitleChanged() { root.title = root.player?.trackTitle ?? "" }
}
```

---

## Delegates de ListView

### Forward reference en `width: childId.implicitWidth`

En un delegate, si `width` referencia un hijo por ID, puede lanzar `ReferenceError` porque `width` se evalúa antes de que los hijos estén instanciados.

```qml
// MAL:
delegate: Item {
    width: myText.implicitWidth + 24   // ReferenceError: myText is not defined
    Text { id: myText; text: "..." }
}

// BIEN — usar TextMetrics (elemento no-visual, se instancia antes):
delegate: Item {
    TextMetrics { id: tm; text: "..."; font.family: "..."; font.pixelSize: 11 }
    width: tm.advanceWidth + 24
    Text { text: tm.text; ... }
}
```

---

## ScrollView

### Scrollbar visible por defecto

`ScrollView` de Qt Quick Controls muestra scrollbar automáticamente.

```qml
// Ocultar sin deshabilitar el scroll:
ScrollView {
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
}
```

---

## Canvas 2D en QML

### No se repinta automáticamente

```qml
// MAL — el canvas no reacciona a cambios de datos:
Canvas { onPaint: { ctx.arc(..., circ.value / 100 * Math.PI * 2) } }

// BIEN — requestPaint() en cada cambio de dato:
Canvas {
    onPaint: { ... }
}
Item {
    onValueChanged: canvas.requestPaint()
    onArcColorChanged: canvas.requestPaint()
}
```

### Colores con `Qt.rgba()`, no strings

```qml
// MAL:
ctx.strokeStyle = "rgba(100, 100, 255, 0.2)"   // puede fallar con colores dinámicos

// BIEN:
const c = circ.arcColor
ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.2)
```

---

## Comportamientos de QML

### `visible: false` en hijos de `Column`

`Column.implicitHeight` excluye automáticamente los hijos con `visible: false`. Aprovecharlo para secciones opcionales:

```qml
Column {
    MediaSection { visible: Mpris.hasPlayer }   // no ocupa espacio cuando no hay player
}
```

### `clip: true` no afecta `implicitWidth`

Un `Item` con `clip: true` recorta el pintado pero no la geometría interna. `implicitWidth` de los hijos sigue siendo su tamaño natural — útil para medir contenido antes de animarlo.

### `Behavior on width` con ancho dependiente de un `ListView`

`playerList.contentWidth` es calculado por Qt incluso cuando `playerList.width === 0` (colapsado). Usar para calcular el ancho destino de la animación.

---

## Procesos externos

### `Process` no acumula stdout entre runs

Cada vez que `running` vuelve a `true`, el parser empieza limpio. Si el comando emite múltiples líneas, acumular en un buffer:

```qml
property string _buf: ""

Process {
    stdout: SplitParser { onRead: line => root._buf += line }
    onRunningChanged: {
        if (running) return
        const data = JSON.parse(root._buf)
        root._buf = ""   // ← limpiar para el próximo run
    }
}
```

### `pactl subscribe` bloquea el proceso

`Audio.qml` corre `pactl subscribe` como proceso permanente (`running: true`). Emite líneas en tiempo real. No usar `onRunningChanged` — procesar en `SplitParser.onRead`.

---

## Wayland / WlrLayershell

### El foco de teclado debe ser explícito

```qml
// Sin esto, el TextInput del launcher no recibe input:
WlrLayershell.keyboardFocus: Visibilities.launcher ? WlrKeyboardFocus.Exclusive
                                                    : WlrKeyboardFocus.None
```

### `exclusiveZone: 44` vs `exclusiveZone: -1`

- La bar usa `44` → reserva espacio, las ventanas no se solapan con ella
- Los paneles usan `-1` → pueden solaparse con cualquier cosa, incluida la bar

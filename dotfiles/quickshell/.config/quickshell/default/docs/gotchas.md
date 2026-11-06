# Gotchas y pitfalls conocidos

Errores reales encontrados durante el desarrollo. Leer antes de tocar servicios o delegates.

---

## Quickshell — registro de tipos (`qmldir`)

### Un archivo `.qml` nuevo NO se ve solo — hay que registrarlo a mano

Cada carpeta del proyecto (`services/`, `modules/launcher/`, `modules/bar/`,
`components/`, etc.) tiene su propio archivo `qmldir` que lista los tipos a
mano — **no** es auto-discovery por nombre de archivo, a pesar de que así
parece funcionar mientras solo se editan archivos ya existentes.

Síntoma si te olvidás: `qs` deja de arrancar (`Configuration Loaded` nunca
aparece), con un error tipo:

```
ERROR:   caused by @modules/launcher/LauncherContent.qml[N:M]: KeybindsList is not a type
```

`qmllint`/`qml` (el runner standalone) NO detectan este problema — el archivo
nuevo es sintácticamente válido y hasta carga bien de forma aislada. El error
solo aparece corriendo `qs` de verdad, porque es el único que respeta el
`qmldir` como manifiesto autoritativo.

```
# services/qmldir — singletons (pragma Singleton):
singleton Keybinds     1.0 Keybinds.qml

# modules/launcher/qmldir — componentes normales:
KeybindsList 1.0 KeybindsList.qml
```

**Regla**: cada vez que se crea un archivo `.qml` nuevo (no al editar uno
existente), agregar la línea correspondiente al `qmldir` de esa carpeta antes
de probarlo con `qs`.

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

---

## Componer wrappers reutilizables (extraídos de `MonitorOsdWindow`/`ColoursEngine`)

### `Variants` trata TODO hijo extra como parte de la expansión por modelo

Si un componente propio tiene una `Variants { model: ...; delegate: ... }`
como raíz y algún caller le agrega hijos extra (`Timer`, `Connections`,
propiedades sueltas) directo en la declaración, esos hijos caen en la misma
default property que `Variants` usa para expandir el modelo — intenta
inyectarles `modelData` como si fueran delegates.

Síntoma:
```
WARN: Setting initial properties failed: Connections does not have a property called modelData
```
y cualquier `id` declarado ahí (`hideTimer`, etc.) queda inaccesible —
`ReferenceError: hideTimer is not defined` en el `Connections` que lo usa.

**Fix**: la raíz del wrapper debe ser un `Item` (u otro tipo con default
property normal) que contenga el `Variants` como hijo — nunca `Variants`
directo si el wrapper va a aceptar hijos extra del caller.

### `QtObject` no tiene default property — no le declares hijos sueltos

```qml
// MAL — "Cannot assign to non-existent default property":
QtObject {
    id: engine
    Process { id: p; command: [...] }   // ← hijo suelto, sin default property
}

// BIEN — Item sí tiene default property ("data"):
Item {
    id: engine
    Process { id: p; command: [...] }   // funciona igual que en cualquier otro archivo
}
```
Alternativa si de verdad se quiere `QtObject`: asignar cada hijo vía
propiedad explícita (`property Process p: Process { ... }`) en vez de
declararlo suelto — pero con varios hijos (`ColoursEngine.qml` tiene 9
`Process`) usar `Item` es mucho menos ruido.

### `Component.createObject(win, {...})` en una `PanelWindow` necesita `win.contentItem`

```qml
// MAL — "Created graphical object was not placed in the graphics scene":
root.content.createObject(win, { win: win, osd: root })

// BIEN — una PanelWindow no es un Item de la escena, su contentItem sí:
root.content.createObject(win.contentItem, { win: win, osd: root })
```

### `createObject` con propiedades iniciales, no `Loader` + `onLoaded`

Si el contenido creado dinámicamente referencia `win.algo` en sus propios
bindings, pasar `win` como propiedad inicial de `createObject(parent, {win})`
evita que esos bindings evalúen una vez con `win = null` antes de que un
`Loader.onLoaded` alcance a asignarlo. Usar `property PanelWindow win: null`
(no `required property`) del lado del contenido — un `required property` no
tiene semántica garantizada para asignación post-creación vía `Loader`.

### `ShellRoot` no soporta `Component.onCompleted` directo

```qml
// MAL — "Non-existent attached object":
ShellRoot {
    Component.onCompleted: { ... }
}

// BIEN — un Item hijo sí lo soporta, y sigue disparando una vez que
// TODO lo declarado arriba terminó de construirse:
ShellRoot {
    Background {}
    Bar {}
    // ...
    Item {
        Component.onCompleted: { ... }
    }
}
```

### Romper un binding loop diferido con `Qt.callLater`

Si el `onStatusChanged`/`onExited` de algo cuyo `source`/`command` depende de
una property, escribe de vuelta a ESA MISMA property (patrón típico:
`Image.source` ← `resolvedSource` ← `bgFailed`, y `Image.onStatusChanged`
setea `bgFailed`), varias properties upstream cambiando en el mismo tick
(ej. un `FileView` grande terminando de cargar y disparando muchos bindings
dependientes a la vez) pueden hacer que QML detecte reentrancia y tire:

```
WARN scene: Binding loop detected for property "resolvedSource"
```

No es un loop infinito real — QML corta la propagación y sigue, pero indica
trabajo de más y un valor intermedio potencialmente incorrecto por un frame.
Diferir la escritura de vuelta rompe la reentrancia sin cambiar el resultado:

```qml
// en vez de: root.bgFailed = true
Qt.callLater(() => { root.bgFailed = true })
```

### Dos properties separadas describiendo el mismo hecho pueden ir desincronizadas un tick

Si `propA` (ej. `useAbsoluteBgSource`) y `propB` (ej. `bgSource`) se computan
por separado pero SIEMPRE deberían estar de acuerdo (ambas dependen, por
caminos distintos, del mismo estado upstream), una tercera property que lee
ambas en la misma expresión (`resolvedSource`) puede leerlas en un instante
donde una ya se recalculó y la otra todavía no — cada una es dirty/clean por
separado, no hay commit atómico entre varias properties que cambian juntas.
Cuando sea posible, derivar el mismo hecho de la MISMA lectura en vez de dos
properties independientes (ej. `bgSource.startsWith("/")` en vez de un flag
`useAbsoluteBgSource` separado) — no puede desincronizarse de sí mismo.

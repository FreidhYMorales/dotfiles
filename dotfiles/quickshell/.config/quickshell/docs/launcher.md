# Launcher (`modules/launcher/`)

App launcher con animación multi-stage. Se abre desde `LauncherButton` en el bar.

---

## `Launcher.qml`

```
WlrLayershell.layer:         WlrLayer.Overlay
WlrLayershell.keyboardFocus: Visibilities.launcher ? WlrKeyboardFocus.Exclusive
                                                    : WlrKeyboardFocus.None
anchors: bottom + left + right
margins: bottom: 8
implicitHeight: 560
```

Keyboard exclusive mientras está abierto — captura todo el input para el campo de búsqueda.  
`visible` mientras `stage !== "closed"` para que la animación de cierre termine antes de ocultarse.  
Dismiss: `MouseArea z:0` + `onClicked: Visibilities.toggle("launcher")`.

`LauncherContent` se ancla al fondo y al centro horizontal, con 600px de ancho.

---

## `LauncherContent.qml`

### State machine

```
OPEN:   precircle ──(320ms)──→ circle ──(180ms)──→ bar ──(360ms)──→ open
CLOSE:  open ──(300ms)──→ bar ──(380ms)──→ circle ──(200ms)──→ closing ──(200ms)──→ closed
```

**Estados:**

| Stage | Panel | Descripción |
|---|---|---|
| `closed` | invisible | estado inicial, no renderiza |
| `precircle` | 60×60 círculo | Canvas dibuja arco girando (0→360°) |
| `circle` | 60×60 círculo | Ícono de Arch Linux visible |
| `bar` | 600×56 rect | Panel rectangular sin lista |
| `open` | 600×panelHeight | Lista de apps + search bar |
| `closing` | 60×60 círculo | Fadeout |

**Dimensiones del panel por stage:**
```qml
width: switch(stage) {
    case "closed"/"precircle"/"circle"/"closing": return 60
    default: return 600
}
height: switch(stage) {
    case "closed"/"precircle"/"circle"/"closing": return 60
    case "bar": return searchH  // 56px
    default: return panelHeight  // listH + searchH + gap
}
radius: stage in ["closed","precircle","circle","closing"] ? 30 : 14
```

Todas las propiedades del `Rectangle#panelRect` tienen `Behavior on` para la transición suave.

### Animaciones

```qml
// OPEN
SequentialAnimation {
    ScriptAction { script: stage = "precircle" }
    NumberAnimation { target: arcCanvas; property: "arcEnd"; from: 0; to: 360; duration: 320; easing: InOutQuart }
    PauseAnimation { duration: 60 }
    ScriptAction { script: stage = "circle" }
    PauseAnimation { duration: 180 }
    ScriptAction { script: stage = "bar" }
    PauseAnimation { duration: 360 }
    ScriptAction { script: { stage = "open"; focusTimer.restart() } }
}

// CLOSE
SequentialAnimation {
    ScriptAction { script: { searchField.text = ""; if (stage === "open") stage = "bar" } }
    PauseAnimation { duration: 300 }
    ScriptAction { script: stage = "circle" }
    PauseAnimation { duration: 380 }
    ScriptAction { script: stage = "closing" }
    PauseAnimation { duration: 200 }
    ScriptAction { script: stage = "closed" }
}
```

`focusTimer` (50ms) llama `searchField.forceActiveFocus()` después de que el panel está en `open`.

### Arc canvas (stage: precircle)

```qml
Canvas {
    property real arcEnd: 0   // 0 → 360 animado
    onArcEndChanged: requestPaint()
    onPaint: {
        // arco clockwise desde arriba, lineCap "round", strokeStyle m3primary
    }
}
```

### Lista de apps

```qml
ListView {
    model: root.filtered       // filtrado reactivo por searchField.text
    opacity: stage === "open" ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 180 } }
    delegate: AppItem { ... }
}
```

Máximo 5 resultados visibles: `listH = Math.min(filtered.length, 5) * itemH`.  
Si no hay resultados y hay texto: muestra "No apps found" centrado.

### Search bar (pinned al fondo)

```
Item (height: 56, anchors.bottom)
├── Separator fino arriba (visible si lista tiene items)
├── Ícono 󰍉 (visible solo en stage "open")
├── Placeholder "Search apps..." (cuando searchField está vacío)
├── TextInput searchField (filtro reactivo)
└── Botón × (clearBtn, animado, visible si hay texto)
```

Keybindings:
- `Keys.onEscapePressed` → `Visibilities.toggle("launcher")`
- `Keys.onReturnPressed` → lanza `filtered[0].exec` y cierra

### Carga de apps

```qml
Process {
    command: ["python3", Paths.scripts + "/list-apps.py"]
    // corre cada vez que se abre el launcher (no en caché permanente)
}
```

Resultado: JSON `[{ name, exec, icon, description }]`.

---

## `AppItem.qml`

```
Item (height: 64)
├── Rectangle hover background (m3onSurface 6% alpha)
├── Row (spacing: 12, padding izquierdo)
│     ├── Image 36×36 (ícono .desktop, fallback texto ícono)
│     ├── Column
│     │     ├── Text nombre (13px Medium)
│     │     └── Text descripción (11px, m3onSurfaceVariant, ElideRight)
│     └── espacio flexible
└── Rectangle divisor inferior (oculto en último ítem)
```

---

## `scripts/list-apps.py`

Parsea archivos `.desktop` de `/usr/share/applications/` y `~/.local/share/applications/`.  
Retorna JSON con `name`, `exec` (limpiado de `%U`, `%F`, etc.), `icon`, `description`.  
Filtra entradas con `NoDisplay=true` y las que no tienen `Exec`.

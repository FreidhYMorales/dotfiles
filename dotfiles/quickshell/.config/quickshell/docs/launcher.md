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

## Sistema de comandos (`>`)

Escribir `>` solo en el search field cambia `root.mode` (`LauncherContent.qml`,
propiedad `mode`, líneas ~31-59) y la lista de apps es reemplazada por la
lista de comandos disponibles. Cada comando entra a su propio modo con un
prefijo + espacio (`>wallpaper `, `>theme `, `>screensaver `, `>keybinds `,
`>webapp `) — seguir escribiendo después del prefijo filtra/interactúa dentro
de ese modo, no cierra ni lanza nada por sí solo. `pickCommand(id)` (click en
un `CommandItem`) completa el prefijo automáticamente.

```qml
readonly property var commands: [
    { id: "wallpaper",   name: "Wallpaper",   description: "Choose the desktop wallpaper" },
    { id: "theme",       name: "Theme",       description: "Choose the color theming mode" },
    { id: "screensaver", name: "Screensaver", description: "Configure screensaver, lock and suspend" },
    { id: "keybinds",    name: "Keybinds",    description: "Keyboard shortcuts cheatsheet" },
    { id: "webapp",      name: "Web App",     description: "Install a web app launcher" }
]
```

### `CommandItem.qml`

Fila de la lista `>` — ícono en círculo + nombre + descripción, mismo patrón
visual que `AppItem.qml` (fondo/barra lateral de selección). Modelado sobre
`AppItem` pero con un glifo Nerd Font fijo en vez de un ícono `.desktop` real,
ya que los comandos no son archivos.

### `>wallpaper` → `WallpaperCard.qml`

Tarjeta del carrusel horizontal (`PathView`) de wallpapers: thumbnail (imagen
o, para videos, un frame extraído vía `Wallpapers.videoFrameCache`) con el
nombre superpuesto sobre un scrim, recortado a rectángulo redondeado con
`MultiEffect` + máscara. Borde `m3primary` de 2px si es el wallpaper activo.

### `>theme` → `ThemeModeItem.qml`

Fila de la lista de modos de theming matugen (los 9 esquemas + claro/oscuro).
El ícono muestra un swatch partido primary/secondary recortado a círculo una
vez que `Colours.generatePreviews()` termina de renderizar la preview de ese
modo contra el wallpaper actual (mientras tanto, muestra el glifo genérico 󰏘);
marca `` a la derecha si es el modo activo.

### `>screensaver` → `ScreensaverForm.qml`

Panel de configuración con 3 columnas de steppers `[−] valor [+]`
(Screensaver / Lock / Suspend, en minutos), un toggle para usar el wallpaper
actual como fondo del salvapantallas, y — si ese toggle está apagado — un
picker de imagen específico para el salvapantallas (mismo patrón visual que
el carrusel de `>wallpaper`).

### `>keybinds` → `KeybindsList.qml`

Cheatsheet de atajos de teclado: `ListView` de solo mouse (no participa del
`selectedIndex`/navegación por teclado del resto del launcher), respaldada
por `services/Keybinds.qml`, que lee en vivo `hyprctl binds -j` en vez de una
copia hardcodeada de los keybinds.

### `>webapp` → `WebAppForm.qml`

Formulario (nombre + URL) para instalar un launcher de web app. Al confirmar
corre `~/.local/bin/webapp-install <name> <url>` como `Process`; si sale con
código 0 muestra "Installed!" y cierra el launcher tras 800ms, si falla
muestra un error inline ("Failed — check URL or name").

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

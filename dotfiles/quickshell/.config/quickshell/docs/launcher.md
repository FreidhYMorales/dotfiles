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

Punto → línea (crece hacia arriba) → brackets (se separan + tics de esquina
+ ícono de Arch adentro) → bar → open — terminal-alike, reemplazó la
animación anterior de círculo+arco.

```
OPEN:   line ──(220+40ms)──→ brackets ──(260+160ms)──→ bar ──(360ms)──→ open
CLOSE:  open ──(300ms)──→ bar ──(180ms)──→ brackets ──(220ms)──→ line ──(180ms)──→ closing ──(160ms)──→ closed
```

**Estados:**

| Stage | Panel (`panelRect`) | Glyph (`introGroup`, `LauncherIntroGlyph.qml`) |
|---|---|---|
| `closed` | invisible, 60×60 | invisible |
| `line` | invisible, 60×60 | dos espinas coincidentes (separation=0) — se lee como una sola línea |
| `brackets` | invisible, 60×60 | espinas separadas + tics de esquina formando `[`/`]` + ícono Arch (`` `` ) |
| `bar` | 600×56, borde 2px | invisible (`opacity` solo en line/brackets) |
| `open` | 600×panelHeight, borde 2px | invisible |
| `closing` | invisible, 60×60 | (glyph ya volvió a `line`/nada antes de llegar acá) |

**Dimensiones del panel por stage** (`panelRect`):
```qml
width:  stage in ["closed","line","brackets","closing"] ? 60 : 600
height: stage in ["closed","line","brackets","closing"] ? 60
      : stage === "bar" ? searchH                          // 56px
      : panelHeight                                        // listH + searchH + gap
radius: Style.cornerRadius   // cuadrado siempre, coincide con los brackets del glyph
opacity: stage in ["closed","closing","line","brackets"] ? 0 : 1
border.width: stage in ["bar","open"] ? 2 : 0   // el glyph dibuja su propio "borde" (los brackets) en line/brackets
```

Todas las propiedades de `panelRect` tienen `Behavior on` para la transición suave.

### Animaciones (`LauncherContent.qml`)

```qml
// OPEN
SequentialAnimation {
    ScriptAction { script: root.stage = "line" }
    NumberAnimation { target: introGroup; property: "spineH"; from: 0; to: introGroup.spineHTarget; duration: 220; easing: OutCubic }
    PauseAnimation { duration: 40 }
    ScriptAction { script: root.stage = "brackets" }
    ParallelAnimation {
        NumberAnimation { target: introGroup; property: "separation"; from: 0; to: introGroup.separationTarget; duration: 260; easing: OutCubic }
        NumberAnimation { target: introGroup; property: "capReveal";  from: 0; to: 1; duration: 260; easing: OutCubic }
    }
    PauseAnimation { duration: 160 }
    ScriptAction { script: root.stage = "bar" }
    PauseAnimation { duration: 360 }
    ScriptAction { script: { root.stage = "open"; focusTimer.restart() } }
}

// CLOSE — mismo camino a la inversa
SequentialAnimation {
    ScriptAction { script: { searchField.text = ""; if (root.stage === "open") root.stage = "bar" } }
    PauseAnimation { duration: 300 }
    ScriptAction { script: root.stage = "brackets" }
    PauseAnimation { duration: 180 }
    ParallelAnimation {
        NumberAnimation { target: introGroup; property: "separation"; to: 0; duration: 220; easing: InCubic }
        NumberAnimation { target: introGroup; property: "capReveal";  to: 0; duration: 220; easing: InCubic }
    }
    ScriptAction { script: root.stage = "line" }
    NumberAnimation { target: introGroup; property: "spineH"; to: 0; duration: 180; easing: InCubic }
    ScriptAction { script: root.stage = "closing" }
    PauseAnimation { duration: 160 }
    ScriptAction { script: root.stage = "closed" }
}
```

`focusTimer` (50ms) llama `searchField.forceActiveFocus()` después de que el panel está en `open`. `Launcher.qml` ancla el panel con `margins.bottom: 10`, igual al `gaps_out` de Hyprland — el borde inferior del launcher coincide con el de las ventanas.

### `LauncherIntroGlyph.qml`

Componente separado (antes vivía inline en `LauncherContent.qml`) — dibuja el glyph de línea/brackets/ícono de arriba. Recibe `stage`/`searchH` como propiedades del padre; `spineH`/`separation`/`capReveal` quedan como propiedades escribibles normales porque las animaciones de `LauncherContent.qml` las setean por `id` desde afuera (`target: introGroup; property: "spineH"`).

⚠️ El ícono de Arch usa `opacity: introGroup.capReveal` — **no** `stage === "brackets"` — porque ese stage se mantiene igual durante la formación Y el colapso de los brackets; atado al stage, el ícono quedaba visible durante todo el cierre en vez de desvanecerse con los tics.

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

### `AppLoader.qml`

Wrapper del `Process` que corre `list-apps.py` (antes vivía inline en `LauncherContent.qml`) — `appLoader.apps` (JSON `[{ name, exec, icon, description }]`) y `appLoader.reload()`, llamado cada vez que se abre el launcher (no hay caché permanente).

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

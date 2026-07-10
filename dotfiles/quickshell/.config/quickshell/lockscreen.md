# Lockscreen — Referencia arquitectural (Caelestia Shell)

Fuente: https://github.com/caelestia-dots/shell/tree/main/modules/lock

## Estructura de componentes

```
Lock.qml (Scope)
└── WlSessionLock                    ← protocolo ext-session-lock-v1
    └── LockSurface.qml              ← una instancia por monitor
        ├── ScreencopyView + blur    ← fondo: captura live con MultiEffect blur
        └── lockContent (animado)
            ├── MaterialIcon "lock"  ← elemento de transición
            └── Content.qml (RowLayout)
                ├── columna izquierda
                │   ├── WeatherInfo.qml   ← open-meteo.com, sin API key
                │   ├── Fetch.qml         ← neofetch visual + paleta de colores
                │   └── Media.qml         ← MPRIS: album art, controles
                ├── Center.qml            ← reloj, fecha, avatar, input
                └── columna derecha
                    ├── Resources.qml     ← CPU%, temp, RAM%, storage (circular)
                    └── NotifDock.qml     ← notificaciones agrupadas por app
```

## Hacks técnicos no obvios

### 1. ScreencopyView previo al lock
El backend ICC de captura debe inicializarse ANTES de que el compositor bloquee
el acceso a las capturas. Sin esto el blur del fondo falla silenciosamente.

```qml
// Inicializar antes del lock real
Loader {
    active: true
    sourceComponent: ScreencopyView { /* solo para init */ }
}
```

### 2. Input de contraseña sin TextInput
Usan un `ListView` horizontal de cuadraditos animados — control total sobre
la presentación, sin texto visible en ningún momento.

```qml
ListView {
    orientation: Qt.Horizontal
    model: ScriptModel { values: root.buffer.split("") }
    delegate: StyledRect {
        // Animación de entrada
        Component.onCompleted: { opacity = 1; scale = 1 }
        // Animación de salida con delayRemove
        ListView.delayRemove: true
        // ... opacity + scale → 0, luego delayRemove = false
    }
}
```

### 3. Dos PamContexts en paralelo
`passwd` y `fprint` corren simultáneamente desde el inicio.
`fprint` necesita reinicio manual — PAM lo reporta `MaxTries` en cada intento
individual, no al llegar al límite real.

```qml
PamContext { id: passwd; config: "passwd" }
PamContext { id: fprint;  config: "fprint"  }
```

### 4. Focus que nunca escapa
```qml
StyledRect {
    onActiveFocusChanged: forceActiveFocus()
    Keys.onPressed: (event) => handleKey(event)
}
```
Las teclas se capturan en el contenedor padre, no en un TextInput.

### 5. Patrón de referencia contable para servicios
```qml
// Activa polling solo cuando el lockscreen está visible
Ref { service: SystemUsage }
```
Cuando no hay consumidores activos, no hay polling de CPU/RAM/storage.

### 6. Animación de entrada/salida
- Entrada: el ícono de lock hace spin 360° + scale-in → luego el dashboard
  hace fade-in + scale-in en una segunda fase
- Salida: proceso inverso — dashboard desaparece, ícono de lock reaparece,
  blur del fondo hace fade-out
- Usa `ParallelAnimation` con fases encadenadas via `onFinished`

## Servicios y fuentes de datos

| Widget | Fuente | Deps |
|---|---|---|
| Clima | api.open-meteo.com + ipinfo.io | ninguna (HTTP nativo) |
| Media | MPRIS via Quickshell.Services | `mpris-proxy` en autostart |
| CPU/RAM/Storage | `/proc/stat`, `/proc/meminfo`, `lsblk`, `sensors` | `lm_sensors` |
| Notificaciones | Quickshell.Services.Notifications | nativo |
| Reloj/Fecha | SystemClock de Quickshell | nativo |
| Batería | UPower D-Bus | nativo |
| Avatar | `~/.face` | ninguna |
| Teclado/CapsLock | Hyprland IPC | nativo |

## Notas de implementación propia

- El clima de open-meteo no requiere API key — solo lat/lon de ipinfo.io
- El `~/.face` es el avatar estándar de FreeDesktop — funciona en cualquier DE
- `sensors` para temperatura de CPU requiere `lm_sensors` configurado
  (`sudo sensors-detect` en sistema nuevo)
- Las notificaciones del lockscreen pueden ocultarse con config `hideNotifs`

## Port del theme SDDM "silent" (implementación actual)

El lockscreen actual (`modules/lock/`) no sigue la arquitectura Caelestia de
arriba tal cual — es un port visual del theme de SDDM "silent"
(`backup/archive/restorations/sddm/themes/silent/`), leyendo los mismos
`.conf` (INI) sin modificarlos. Reemplaza el blur en vivo (`ScreencopyView`)
por fondo estático configurable, y el input de cuadraditos por un
`TextField` enmascarado real, para calzar con el greeter real.

- **`services/LockConfig.qml`** — singleton que parsea el `.conf` activo vía
  `FileView`, exponiendo las mismas ~150 propiedades que el `Config.qml` del
  theme (mismos nombres, mismas keys `Section/key`).
- **Elegir tema**: variable de entorno `QS_LOCK_THEME` con el nombre del
  archivo sin extensión (ej. `QS_LOCK_THEME=catppuccin-mocha`). Sin setear,
  usa `custom` (→ `modules/lock/assets/configs/custom.conf`). Se resuelve
  una sola vez al iniciar el shell — no hay cambio de tema en caliente
  todavía (los 12 `.conf` son archivos completos, no deltas, así que cambiar
  cuál está activo es mecánicamente simple de agregar más adelante).
- **`custom.conf` usa el wallpaper real como fondo**: `background = wallpaper`
  en `[LockScreen]`/`[LoginScreen]` es un valor sentinel (no un nombre de
  archivo real) que `LockSurface.qml` detecta (`useWallpaperBg`) y resuelve
  directo contra `Wallpapers.current` (el wallpaper de escritorio activo) —
  **nunca** contra `IdleManager.effectiveScreensaverSource`, aunque las dos
  fuentes coincidían por casualidad antes de que existiera el panel
  `>screensaver` (ver `idle-screensaver.md`, gotcha #15): ese panel permite
  que el salvapantallas use una imagen DISTINTA del wallpaper real
  (`screensaverUseWallpaper: false`), y el sentinel del lockscreen tiene que
  seguir mostrando siempre el wallpaper real, no la del salvapantallas.
  Durante la fase idle sin revelar el prompt (`useScreensaverBg`), sí se
  muestra `effectiveScreensaverSource` — es el propio salvapantallas
  renderizándose dentro del lock, ahí sí puede ser una imagen distinta a
  propósito. Cualquier otro `.conf` puede optar por el mismo mecanismo
  poniendo `background = wallpaper` en vez de un nombre de archivo — los
  temas restantes (default, catppuccin-*, etc.) siguen usando sus propios
  fondos estáticos en `modules/lock/assets/backgrounds/` sin tocar.
- **`custom.conf` mapea sus acentos a la paleta matugen en vivo**: mismo
  mecanismo de sentinel que el fondo, pero para color — `LockConfig.colorValue(key,
  fallback)` intercepta valores como `m3primary`/`m3onPrimaryContainer` (cualquier
  nombre de rol de `Colours.palette`) y devuelve el `color` real en lugar de
  intentar parsearlo como hex; si el valor no matchea ningún rol, cae al hex
  literal de siempre. Como es una lectura de propiedad normal dentro del
  binding, es reactivo — cambia de wallpaper o de modo de tema y el
  lockscreen se recolorea solo, sin reiniciar el shell.
  - **Alcance deliberado — "solo acentos"**: se tocaron los pares
    background/content de `PasswordInput`, `LoginButton`, el popup activo de
    `MenuArea.Popups`, y el `active-content-color` de Layout/Keyboard/Power
    (→ `m3primary`/`m3primaryContainer`/`m3onPrimary`/`m3onPrimaryContainer`).
    Reloj, mensaje y texto general quedaron con sus colores fijos (sin atar
    a la paleta) a propósito, para no arriesgar legibilidad sobre wallpapers
    muy claros/oscuros sin sombra/outline implementado.
  - **Excepción — fecha**: `LockScreen.Date/color` sí quedó atado a
    `m3primary` (era `#FF0000` fijo, no combinaba con varios wallpapers) —
    decisión explícita del usuario de aceptar ese mismo riesgo de
    legibilidad a cambio de que combine siempre con la paleta activa.
  - **Campos NO tocados a propósito, ya inertes en custom.conf**: todos los
    `border-color` del archivo (`avatar`, `password-input`, `login-button`)
    son invisibles porque su `border-size`/`active-border-size` correspondiente
    ya está en `0` — cambiarles el color no habría tenido ningún efecto
    visual sin también subir ese tamaño, que no se pidió. La sección
    `[LoginScreen.MenuArea.Session]` y todo `[LoginScreen.VirtualKeyboard]`
    tampoco se tocaron: ninguna de las dos está consumida por ningún
    `modules/lock/*.qml` (confirmado por grep) — el lockscreen es de un solo
    usuario (sin selector de sesión) y el teclado virtual sigue sin su
    estilo propio portado (pendiente #2 más abajo), así que esas keys son
    puro remanente del theme original sin efecto.
- **Assets**: `modules/lock/assets/{configs,backgrounds,icons}/` — copiados
  byte a byte del theme, incluyendo los fondos en video (`.mp4`, vía
  `QtMultimedia.Video`).
- **Estilo custom del teclado virtual portado** (`vkeyboardStyle`, ~1650
  líneas) — vive ahora en
  `modules/lock/assets/vkeyboard-styles/QtQuick/VirtualKeyboard/Styles/LockKeyboard/style.qml`.
  Port mecánico: todo `Config.` → `LockConfig.` (mismos nombres de
  propiedad, ver sección de arriba), y todo `resourcePrefix + "x.svg"` →
  `LockConfig.getIcon("x.svg")`. Tamaños sin tocar — el archivo no tiene
  ninguna referencia a `Config.generalScale` (grep vacío); todo tamaño sale
  de `scaleHint`, una propiedad del tipo base `KeyboardStyle` de Qt que se
  calcula sola a partir del tamaño real del panel — que ya viene escalado
  por `LockConfig.generalScale * (Screen.width / 1920)` desde
  `LockVirtualKeyboard.qml` (línea del `width` del `InputPanel`), así que
  duplicar el factor acá adentro habría escalado dos veces.
  - **Gotcha real — no existe `QT_VIRTUALKEYBOARD_STYLESPATH` en Qt6**
    (verificado contra los binarios instalados de `qt6-virtualkeyboard`
    6.11.1 con `strings` y contra la documentación oficial — solo existe
    `QT_VIRTUALKEYBOARD_STYLE`, que selecciona un nombre, no agrega un path
    de búsqueda). El mecanismo real es el `QML_IMPORT_PATH` estándar de Qt:
    hay que agregar como import path la carpeta que contiene
    `QtQuick/VirtualKeyboard/Styles/<nombre>/style.qml` (structure
    verificada con un smoke test aislado antes de portar las 1650 líneas
    reales). `LockVirtualKeyboard.qml` selecciona el estilo con
    `VirtualKeyboardSettings.styleName = "LockKeyboard"` en su
    `Component.onCompleted`, pero **el env var hay que exportarlo ANTES de
    lanzar `qs`** — no hay forma de agregar import paths a un engine QML ya
    corriendo:
    ```
    export QML_IMPORT_PATH="/home/deadlock/Mio/Configuraciones/backup/quickshell/modules/lock/assets/vkeyboard-styles"
    ```
  - **4 colores atados a la paleta, el resto se dejó fijo** (mismo criterio
    "solo acentos" de la sección de arriba): `primary-color` (acento de
    caps-lock + acento de mode-key), `key-active-background-color`
    (highlight de tecla presionada), `selection-background-color` y
    `selection-content-color` (selección de texto) pasaron de
    `root.stringValue(key) || fallback` a `root.colorValue(key, fallback)`
    en `LockConfig.qml`, y `custom.conf` ahora referencia
    `m3primary`/`m3primaryContainer`/`m3onPrimary` en vez de hex fijo.
    `key-color`, `key-content-color`, `background-color` y `border-color`
    quedaron en hex fijo — no son accent/focus/selección.
  - **Dos bugs reales del port (no cosméticos), encontrados recién al
    probarlo en vivo**: el estilo original referencia un `id: loginScreen`
    ambiental de SDDM (alcanzable ahí porque el greeter comparte un único
    scope de documento) que acá no existe — el `ReferenceError` resultante
    hacía fallar `visible`/`enabled`/`hoverEnabled` de **cada tecla**
    (quedaban cerradas), y el botón de ocultar teclado (`loginScreen.showKeyboard
    = false`) no hacía nada. Fix: `visible: true` en los ~10 lugares, y
    `Qt.inputMethod.hide()` (API estándar de Qt) para el botón de ocultar.
    Un tercer warning (`traceInputGuideConnections`) en `Component.onDestruction`
    es un bug preexistente del theme original (mismo patrón, mismas líneas
    byte a byte) — un `id` declarado dentro de un `Component` referenciado
    desde afuera de su scope; se sacó el cleanup muerto en vez de portarlo.
  - **Posición del teclado — `GridLayout.height` no es de fiar como hijo
    suelto de un `Item`, ni siquiera atándolo a mano**: `LockVirtualKeyboard.belowY`
    se deriva de la geometría de `loginContainer` (el `GridLayout` de
    avatar+username+password). Confirmado en 4 rondas de logs en vivo:
    `loginContainer.implicitHeight` leía correctamente `100` (coincidía con
    el avatar) pero `loginContainer.height` se quedaba en `0` — posicionando
    el teclado en el borde SUPERIOR del área de login en vez de debajo. El
    ancho coincidía con `implicitWidth` por casualidad (`302`=`302`), no por
    el mismo mecanismo — de ahí lo confuso de diagnosticar. Se probó atar
    `height: implicitHeight` explícitamente en el propio `GridLayout` — NO
    alcanzó: el layout pisa cualquier asignación externa a su propia
    `height`/`width` con su gestión interna de geometría (misma familia de
    bug que "los anchors siempre ganan", ya documentada en este proyecto).
    **Fix real**: en vez de pelear con `loginContainer.height`, leer
    `loginContainer.implicitWidth`/`implicitHeight` directamente en
    `belowX`/`belowY` — esos dos valores se mantuvieron correctos en las 4
    rondas de prueba. Además, `avatar` (un `Rectangle` con `width`/`height`
    propios pero sin `Layout.preferredWidth/Height`) ahora expone
    `Layout.preferredWidth/Height` explícitos — sin esto, `implicitHeight`
    del `GridLayout` no contaba el tamaño real del avatar en el cálculo de
    esa fila. **Lección para el futuro**: un `GridLayout`/`RowLayout`/`ColumnLayout`
    usado como hijo directo de un `Item` común (no de otro Layout) — leer
    siempre `implicitWidth`/`implicitHeight` desde afuera, nunca
    `width`/`height`; y ese mismo `GridLayout` nunca se debe usar como
    `mapToItem` target/source dentro de un binding reactivo tampoco (ver
    intento rechazado en la memoria del proyecto, `mapToItem` no crea
    dependencia automática sobre la posición de los ancestros).
- **Fases 0–6 completas**: `LockConfig` → fondo/reloj/mensaje → avatar+PAM →
  PowerMenu → selector de layout (`services/LockLayouts.qml`, vía `hyprctl`)
  → teclado virtual → pulido (escala independiente de resolución/DPI,
  posicionamiento del bloque avatar+usuario+password vía `GridLayout`). Ver
  memoria del proyecto (`quickshell/lockscreen-sddm-port`) para el detalle de
  cada fase y los bugs encontrados en el camino.
- **Escala independiente del monitor**: todo tamaño/font-size derivado de
  `LockConfig.generalScale` se multiplica también por `(Screen.width / 1920)`
  en los 10 archivos de `modules/lock/*.qml` — ancla el diseño a una
  resolución de referencia de 1920×1080 física, para que subir el scale de
  Hyprland (HiDPI) no achique ni agrande el lockscreen.
- **Botones de Lock/Logout del dashboard** (`modules/dashboard/ProfileSection.qml`,
  `SessionSection.qml`): `Lock` usa `qs ipc -p <path> call lock lock` (sin
  `-p` asume la config `"default"`, que no existe acá). `Logout` usa
  `hyprctl dispatch 'hl.dsp.exit()'` — este build de Hyprland enruta TODO
  `dispatch`/`keyword` por un puente Lua, los nombres de dispatcher nativos
  (`exit`, etc.) ya no funcionan solos.

### Pendientes reales (no resueltos, a revisar)
1. **`services/Colours.qml:151`** — `FileView.text` es función, no
   propiedad; falta el `()`. El pipeline de colores de matugen
   probablemente nunca parseó bien. Deferido a propósito, no tocar sin pedido
   explícito.
2. ~~Estilo custom del teclado virtual sin portar~~ — portado, ver sección
   "Estilo custom del teclado virtual portado" más arriba. Falta que el
   usuario exporte `QML_IMPORT_PATH` antes de lanzar `qs` (no queda
   persistido en ningún launcher todavía — no hay exec-once/systemd para
   quickshell, ver CLAUDE.md del proyecto).
3. **`LockConfig.lockScreenDisplay`** (saltar la pantalla ociosa) — se
   parsea pero no se consume en ningún lado.
4. **`LockIconButton.qml`** tiene un `Component.onCompleted` (cálculo de
   ancho de label) con el mismo patrón de riesgo de carrera que se
   encontró y arregló en `LockAuth.qml`/`LockIdle.qml`/`LockMenuArea.qml`
   — nunca se reportó síntoma ahí, no se tocó.

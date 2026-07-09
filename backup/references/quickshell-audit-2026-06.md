# Auditoría Quickshell propio vs Caelestia

**Fecha:** 2026-06-28  
**Referencia:** `/home/deadlock/Clones/shell` (Caelestia upstream)  
**Proyecto auditado:** `backup/quickshell/`

---

## Resumen ejecutivo

El proyecto está sólido en estructura general y tiene las piezas correctas en su lugar. Sin embargo, hay dos features muertos en runtime que no se notan en compilación, varios bugs de flicker idénticos al que ya se corrigió en `Network.qml`, y uso generalizado de procesos externos donde existen APIs nativas de Quickshell/Qt.

---

## 1. Lo que está roto (silencioso en runtime)

### `NotificationPanel` nunca se instancia
El módulo existe, el `qmldir` lo exporta, `NotificationButton` está implementado — pero nadie hace `NotificationPanel {}` en `shell.qml`. La ventana de notificaciones no existe en runtime.

### `NotificationButton` no está en la barra
`BarContent.qml` no lo incluye en el Row derecho. Los dos extremos del feature están desconectados.

### `LockAuth.qml:138` — path con username hardcodeado
```qml
source: "file:///home/deadlock/.face"  // roto en cualquier otra máquina
```
**Fix:** `Paths.home + "/.face"`

### Lock sin IPC externo
No hay `CustomShortcut { name: "lock" }` ni `IpcHandler`. No hay forma de activar el lock desde fuera del proceso (hyprlock lo hace nativo; el lock propio no tiene ese endpoint).

---

## 2. Bugs de performance / flicker

### `Bluetooth.qml` — mismo flicker que `Network.qml` (ya corregido)
`root.connected = false` se asigna al inicio del timer antes de que el proceso termine. Mismo patrón; mismo fix: bufferizar en props privadas del `Process` y aplicar en `onRunningChanged`.

### `Brightness.qml` — 8 procesos por segundo
Dos `Process` polleando cada 250ms (`brightnessctl get` + `brightnessctl max`).  
**Fix:** `FileView { path: "/sys/class/backlight/.../brightness"; watchChanges: true }` — reactividad real, cero polling, cero procesos.

### `SysInfo.qml` — bash para leer una variable de entorno
```qml
Process { command: ["bash", "-c", "echo $USER"] }
```
`Quickshell.env("USER")` ya existe. El timer a 2s además dispara 4-5 procesos simultáneos.

### `Mpris.qml` — polling de 1s sin necesidad
`Timer { interval: 1000; repeat: true }` refreshea estado aunque nada cambie.  
**Fix:** `Connections { target: Mpris.players; function onValuesChanged() { ... } }`

### `BgAppsWidget.qml` — `hyprctl clients -j` cada 3s
`Hyprland.toplevels.values` es una lista reactiva nativa. No hace falta el proceso.

### `WorkspacesWidget.qml` — `execDetached(["hyprctl", "dispatch"])`
`Hyprland.dispatch()` hace lo mismo por socket directamente.

---

## 3. Código con valores hardcodeados (no reactivos al tema)

| Archivo | Problema |
|---|---|
| `StyledText.qml:15` | `color: "#cdd6f4"` — literal Catppuccin, ignorado por matugen |
| `IconButton.qml:31-34` | `"#cba6f7"`, `"#313244"` — literales Catppuccin Mocha |
| `Battery.qml` | `/sys/class/power_supply/BAT0/` hardcodeado — falla si la batería tiene otro nombre |
| `Network.qml` | `wlan0` hardcodeado — falla si la interfaz activa tiene otro nombre |
| `LockAuth.qml:138` | `"file:///home/deadlock/.face"` — ver sección 1 |

---

## 4. Arquitectura

### `pragma ComponentBehavior: Bound` faltante
Archivos con delegates/Repeaters que no tienen el pragma:
- `LauncherContent.qml`
- `WorkspacesWidget.qml`
- `BgAppsWidget.qml`
- `NotificationPanelContent.qml` (si existe)

Sin esto, los delegates acceden propiedades del scope externo sin `required` — silently unsafe y se rompe en futuras versiones de QML.

### Imports relativos
El proyecto usa `"../../services"`, `"../../components"` en todos lados. Caelestia usa módulos con namespace registrados por CMake (`import qs.services`). Los relativos son frágiles ante reorganizaciones y no escalan. Los `qmldir` no tienen directiva `module`.

### Topología de ventanas Wayland
El proyecto crea una `PanelWindow` por cada panel: Bar, Launcher, Dashboard, NotificationPanel, VolumePopout, Osd, BatteryProfileOsd, Lock — 7+ superficies Wayland. Caelestia usa arquitectura `Drawers` donde todos los paneles viven en una sola `ContentWindow` con visibilidad controlada por `DrawerVisibilities`. Menor overhead en el compositor.

### `Colours.qml` — double-notify en `palette`
`palette` y `tPalette` son `QtObject` que re-exponen las propiedades de `root`. Cada cambio dispara bindings en `root` Y en `palette` — doble notificación para los consumidores. `tPalette` tiene alphas hardcodeados (0.85, 0.75, 0.80…). Sin `ImageAnalyser`, sin `wallLuminance`, sin toggle light/dark dinámico.

### `AnimLoader.qml` — posible dead code
`swapTimer` setea `ldr.sourceComponent` al mismo valor que ya tiene el binding. Revisar si tiene propósito real.

### `StateLayer.qml` — placeholder, no M3 real
Implementado como `Rectangle + MouseArea` con tint hover/press. Caelestia implementa el ripple M3 completo: `Shape` con `RadialGradient`, tracking de posición de press (`pressX`, `pressY`), expansión animada de `circleRadius`, fade-out al soltar.

### `Osd.qml` / `VolumePopout.qml` — código de "ears" duplicado
El `Shape + ShapePath` de las orejas del card está copiado en ambos archivos. Candidato obvio para componente reutilizable.

### `CachingImage.qml` — sin soporte HiDPI
Falta `sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)`. En HiDPI las imágenes se ven borrosas.

### `LauncherContent.qml` — exec field sin sanitizar
```qml
Quickshell.execDetached(["bash", "-c", modelData.exec])
```
Los campos `Exec` de archivos `.desktop` contienen placeholders (`%f`, `%u`, `%F`, `%U`, `%k`) que deben eliminarse antes de ejecutar. No se hace.

### `Time.qml` — allocation JS cada segundo
`Timer` + `new Date()` crea un objeto en el heap de JS cada segundo (minor GC trigger).  
**Fix:** `SystemClock { precision: SystemClock.Seconds }` — nativo, sin allocations.

### `MaterialIcon.qml` — sin variable font axes
`font.family: "Material Symbols Rounded"` sin soporte de fill/grade/weight configurables. Caelestia usa `Tokens.font.icon.*` con axes por tema (grade -25 en dark mode, 0 en light).

---

## 5. Components faltantes vs Caelestia

| Component | Uso |
|---|---|
| `StyledFlickable` | Scrollable con fade edges |
| `VerticalFadeListView` | ListView con fade top/bottom |
| `CircularProgress` | Indicador de progreso circular |
| `FilledSlider` / `StyledSlider` | Sliders M3 completos |
| `StyledSwitch` | Toggle M3 |
| `M3TextField` | Campo de texto M3 |
| `CoverArt` | Album art con fallback y cache |
| `LazyListView` | ListView con carga lazy |
| `AnchorAnim` | Animación de anchors declarativa |
| `WavyLine` | Línea ondulada animada |

---

## 6. Lock screen

Estado actual: placeholder funcional con PAM, blur + overlay, clock, avatar, password pill.

**Pendiente para el lock completo:**
- Descubrir `/.face` dinámicamente (`Paths.home + "/.face"`)
- Screencopy warm-up antes de activar el lock (evita rechazo del compositor)
- IPC para activar externamente (`CustomShortcut` o `IpcHandler`)
- Rediseño visual completo después de implementar plugins (bloqueado por `M3Shapes`)

---

## 7. Plugins C++ pendientes (ordenados por impacto)

| Plugin | Impacto | Reemplaza en el proyecto |
|---|---|---|
| `TickingService` (Cpu/Memory) | **Alto** | grep/df via Process en SysInfo |
| `AppDb` + `AppEntry` | **Alto** | Python script en cada apertura del launcher; sin historial de uso |
| `Requests` (HTTP nativo) | **Medio** | curl via Process en Weather |
| `ImageAnalyser` | **Medio** | Sin análisis de luminancia → sin light/dark dinámico |
| `SessionManager` | **Medio** | No existe — no se puede cerrar sesión desde el shell |
| `Storage` (persistencia) | **Medio** | Sin estado cross-reload (launcher frecuencia, config) |
| `HyprDevices` | **Bajo** | Polling bash/python para keyboard layout, capslock |
| `M3Shapes` | **Bajo** (solo visual) | Lock screen placeholder; ninguna otra pantalla lo necesita |
| `Qalculator` | **Bajo** | Sin evaluador matemático en launcher |

---

## 8. Lista de pendientes priorizados

### BLOQUEANTE
- [ ] Agregar `NotificationPanel {}` a `shell.qml`
- [ ] Agregar `NotificationButton` al Row derecho de `BarContent.qml`
- [ ] `LockAuth.qml:138` — `"file:///home/deadlock/.face"` → `Paths.home + "/.face"`
- [ ] `Lock.qml` — agregar `CustomShortcut` mínimo para bloquear externamente

### ALTA
- [ ] `Brightness.qml` — migrar a `FileView { watchChanges: true }` (eliminar 8 procesos/segundo)
- [ ] `Bluetooth.qml` — mismo fix de flicker que `Network.qml`
- [ ] `Battery.qml` — descubrir ruta de batería dinámicamente, no hardcodear `BAT0`
- [ ] `SysInfo.qml` — `Quickshell.env("USER")` en lugar de proceso bash
- [ ] `Mpris.qml` — eliminar Timer de 1s; usar `Connections` sobre `valuesChanged`
- [ ] `BgAppsWidget.qml` — `Hyprland.toplevels.values` en lugar de `hyprctl clients -j`
- [ ] `WorkspacesWidget.qml` — `Hyprland.dispatch()` en lugar de `execDetached`
- [ ] `LauncherContent.qml` — filtrar placeholders `%f %u %F %U %k` del campo `Exec`
- [ ] `pragma ComponentBehavior: Bound` en los 4 archivos con delegates
- [ ] `Lock.qml` — screencopy warm-up asíncrono

### MEDIA
- [ ] `StyledText.qml:15` — `"#cdd6f4"` → `Colours.m3onSurface`
- [ ] `IconButton.qml` — reemplazar literales Catppuccin con `Colours.*`
- [ ] `CachingImage.qml` — agregar `sourceSize` para HiDPI
- [ ] Extraer `ShapePath` de "ears" a componente (duplicado en `Osd.qml` y `VolumePopout.qml`)
- [ ] `Time.qml` — migrar a `SystemClock { precision: SystemClock.Seconds }`
- [ ] `Network.qml` — detectar interfaz activa dinámicamente, no hardcodear `wlan0`
- [ ] `AnimLoader.qml` — revisar si `swapTimer` tiene propósito real
- [ ] `Colours.qml` — revisar double-notify del `palette` QtObject

### BAJA (requieren plugins o refactor grande)
- [ ] Type annotations en funciones de services
- [ ] `Weather.qml` — migrar de curl a HTTP nativo (requiere plugin `Requests`)
- [ ] `Launcher` — frecuencia de uso + `AppDb` en memoria (requiere plugin)
- [ ] `CAnim.qml` — parametrizar duración desde tokens (requiere sistema de config)
- [ ] `StateLayer.qml` — ripple M3 real (requiere `Shape` + `RadialGradient`)
- [ ] Imports relativos → módulos con namespace (refactor grande)
- [ ] Arquitectura `Drawers` — una sola ContentWindow (refactor mayor)

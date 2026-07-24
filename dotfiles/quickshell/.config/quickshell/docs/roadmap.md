# Roadmap y estado del proyecto

---

## Estado actual

### ✅ Completado y funcional

| Módulo | Archivos | Notas |
|---|---|---|
| Bar (estructura) | `Bar.qml`, `BarContent.qml` | Multi-monitor, WlrLayershell Top |
| LauncherButton | `bar/LauncherButton.qml` | |
| WorkspacesWidget | `bar/WorkspacesWidget.qml` | Dots animados, click cambia WS |
| ClockWidget | `bar/ClockWidget.qml` | Click abre `CalendarPopout` (`Visibilities.toggle("calendar")`) |
| BgAppsWidget | `bar/BgAppsWidget.qml` | Hover expand, hyprctl clients |
| CpuWidget | `bar/CpuWidget.qml` | No estaba en visión original — decisión: se queda en el bar tal cual |
| RamWidget | `bar/RamWidget.qml` | No estaba en visión original — decisión: se queda en el bar tal cual |
| VolumeWidget | `bar/VolumeWidget.qml` | Click abre el OSD de volumen (`Osd.qml`); click derecho abre `wiremix` (mixer PipeWire completo) en kitty |
| BatteryWidget | `bar/BatteryWidget.qml` | Solo display |
| BluetoothWidget | `bar/BluetoothWidget.qml` | Click abre `bluetui` en kitty — lee `services/Bluetooth.qml` |
| WifiWidget | `bar/WifiWidget.qml` | Click abre `impala` en kitty — lee `services/Network.qml` |
| DashboardButton | `bar/DashboardButton.qml` | Con badge de notif unread |
| Dashboard panel | `dashboard/Dashboard.qml` | Panel derecho 340px |
| Dashboard content | `dashboard/DashboardContent.qml` | Panel de perfil fijo arriba + 4 cápsulas con scroll sin scrollbar, todas sobre `components/Capsule.qml` |
| ProfileSection | `dashboard/ProfileSection.qml` | Fila de power terminal-alike (sin fondo/borde propio, solo divisor) |
| BatterySection | `dashboard/BatterySection.qml` | `SegmentedMeter` (bloques discretos), no barra continua |
| PerformanceSection | `dashboard/PerformanceSection.qml` | Filas con `BlockMetric`/`SegmentedMeter`, CPU/RAM/GPU/Disk — reemplazó el `CircleMetric` (arco en Canvas) anterior |
| MediaSection | `dashboard/MediaSection.qml` | MPRIS completo, selector multi-player |
| ~~SessionSection~~ | `dashboard/SessionSection.qml` | ⚠️ **código muerto** — registrado en `qmldir`, no lo instancia nadie |
| ~~DashboardNotificationsSection~~ | `dashboard/DashboardNotificationsSection.qml` | ⚠️ **código muerto** — registrado en `qmldir`, no lo instancia nadie |
| Launcher | `launcher/Launcher.qml` | Keyboard exclusive, bottom-center |
| LauncherContent | `launcher/LauncherContent.qml` | Animación multi-stage (line→brackets→bar→open), 846 líneas — glyph de apertura y loader de apps extraídos a `LauncherIntroGlyph.qml`/`AppLoader.qml` |
| AppItem | `launcher/AppItem.qml` | |
| NotificationPanel | `notifications/NotificationPanel.qml` | Wireado en `shell.qml` (`NotificationPanel {}`) |
| NotificationPanelContent | `notifications/NotificationPanelContent.qml` | 3 tabs |
| NotificationButton | `bar/NotificationButton.qml` | Wireado en `BarContent.qml`, abre `NotificationPanel` |
| NotificationsTab | `notifications/NotificationsTab.qml` | Lista + clear all |
| CalendarTab | `notifications/CalendarTab.qml` | Mensual navegable |
| WeatherTab | `notifications/WeatherTab.qml` | wttr.in, refresco 30min |
| NotificationItem | `notifications/NotificationItem.qml` | Urgencias, dismiss |
| Colours service | `services/Colours.qml` | Hot-reload matugen |
| Time service | `services/Time.qml` | |
| Battery service | `services/Battery.qml` | udevadm monitor |
| Audio service | `services/Audio.qml` | pactl subscribe |
| SysInfo service | `services/SysInfo.qml` | CPU/RAM/GPU/Disk, NVIDIA detect |
| Mpris service | `services/Mpris.qml` | Multi-player, reactivo explícito |
| NotifStore service | `services/NotifStore.qml` | In-memory ListModel |
| Visibilities service | `services/Visibilities.qml` | Mutex de paneles |
| Lock screen | `modules/lock/` (12+ componentes) | Port visual completo del theme SDDM "silent", fases 0-6 terminadas — ver `lockscreen.md` en la raíz |
| Idle chain + caffeine | `services/IdleManager.qml`, `modules/lock/LockSurface.qml` (modo screensaver) | Salvapantallas → auto-bloqueo → auto-suspensión, nativo con `Quickshell.Wayland` — ver `idle-screensaver.md` |
| Wallpaper + theming picker | `services/Wallpapers.qml`, `services/Colours.qml`, `modules/background/` | Picker en el launcher (`>wallpaper`, `>theme`), fondo propio renderizado por Quickshell — ver `wallpaper-theming.md` |
| Wallpaper + colores por monitor | `services/Wallpapers.qml` (`perScreen`), `services/Colours.qml` (`paletteFor`/`palettes`), tabs de monitor en `>wallpaper` | Cada monitor puede tener su propio wallpaper + paleta (matugen `--dry-run`, no toca colors.json/kitty/Hyprland/etc). `eDP-*` (pantalla del laptop) = el tema general; monitores externos quedan independientes. Tab "All" sincroniza todo a un solo wallpaper. Barra + OSDs (`Osd`, `BatteryProfileOsd`, `TrayMenuOsd`, `RecorderModeOsd`, `CalendarPopout`) ya leen la paleta por pantalla — Dashboard/Notifications/Launcher siguen con la paleta global |
| OSD | `bar/Osd.qml`, `bar/BatteryProfileOsd.qml`, `bar/TrayMenuOsd.qml`, `bar/RecorderModeOsd.qml` | Overlays de volumen/brillo/perfil de energía/tray/grabador, wireados en `shell.qml` |
| Screen recorder | `services/Recorder.qml`, `bar/RecorderWidget.qml`, `bar/RecorderModeOsd.qml` | gpu-screen-recorder (screen/region/window) — ver `recorder.md` |
| Screensaver panel | `launcher/ScreensaverForm.qml`, `screensaver/ScreensaverPreview.qml` | Panel `>screensaver` en el launcher, timeouts encadenados (screensaver/lock/suspend) — ver `idle-screensaver.md` y `wallpaper-theming.md` |
| Keybind cheatsheet | `launcher/KeybindsList.qml`, `services/Keybinds.qml` | Comando `>keybinds` en el launcher, wireado en `LauncherContent.qml` |

---

### Auditoría de performance + arquitectura (quickshell)

Auditoría completa del shell, dos tandas:

**Performance**
- `services/SysInfo.qml`: CPU/RAM via `FileView` en vez de `grep`/`bash` por proceso (cero fork/exec por tick)
- `services/Hypr.qml`: eliminado el subsistema entero de capslock/numlock/keyboard-layout — cero consumidores en todo el proyecto
- `services/Brightness.qml`: intervalo de polling 250ms → 500ms

**Arquitectura**
- 15+ archivos de código muerto borrados (`components/{containers,effects,images,misc,widgets}/`, `MaterialIcon.qml`, `AnimLoader.qml`, `Logo.qml`, etc.) — todos sin ningún call site
- `components/StateLayer.qml` (existía sin usar) conectado en 5 archivos que repetían el patrón de hover/press a mano (`NotificationItem`, `CalendarCard`, `CalendarTab`, `MediaSection`, `TrayMenuOsd`)
- `components/Capsule.qml` — estilo de tarjeta del dashboard (antes repetido 5 veces) extraído a un componente compartido
- `components/MonitorOsdWindow.qml` — esqueleto de `PanelWindow` por monitor compartido por `TrayMenuOsd`/`BatteryProfileOsd`/`RecorderModeOsd` (antes duplicado en los 3)
- `LauncherContent.qml` (965 → 846 líneas) — glyph de apertura extraído a `LauncherIntroGlyph.qml`, loader de apps a `AppLoader.qml`
- `Colours.qml` (614 → 334 líneas) — todo el spawneo de procesos de matugen/ffmpegthumbnailer movido a `services/ColoursEngine.qml`, API pública sin cambios

Detalle completo en `docs/gotchas.md`, `docs/components.md`, `docs/services.md`, `docs/launcher.md`, `docs/dashboard.md`, `docs/bar.md`.

### Lockscreen — 3 bugs encontrados y resueltos

- Wallpaper mostrando `default.jpg` en el primer bloqueo tras reinicio (carrera con `Wallpapers.current` cargando async)
- `LockConfig.lockScreenDisplay` se parseaba pero nunca se conectaba — ahora salta la pantalla idle cuando está en `false`
- `LockIconButton.qml` — mismo patrón de carrera de `Component.onCompleted` que ya se había arreglado en otros archivos del lock, alcanzable de verdad vía `LockPowerMenu.qml`

Detalle en `lockscreen.md`.

---

## Decisiones tomadas

| Decisión | Elección |
|---|---|
| ¿`CpuWidget` y `RamWidget` en el bar? | Conservar tal cual — quedan en el bar |

---

## Phase 4 — Paneles auxiliares

- [x] `OSD` — overlay para cambios de volumen/brillo — implementado (`bar/Osd.qml`), wireado en `shell.qml`
- [x] `VolumePopout` — resuelto sin construir un panel QML propio: click derecho en `VolumeWidget` abre `wiremix` (mixer PipeWire completo, sink/source picker) en kitty, mismo patrón que Bluetooth/Wifi. Requiere `yay -S wiremix` (AUR, no instalado por defecto). El OSD de volumen (`Osd.qml`) sigue cubriendo el caso rápido de "cambiaste el volumen".
- [x] `BluetoothPanel` — resuelto igual: `BluetoothWidget` ya abre `bluetui` (TUI completa: lista de dispositivos, toggle, connect/disconnect) en kitty. No hace falta un panel QML nativo.
- [x] `NetworkPanel` — resuelto igual: `WifiWidget` ya abre `impala` (TUI completa: redes, señal, conectar/desconectar) en kitty. No hace falta un panel QML nativo.
- [x] `BluetoothWidget` / `WifiWidget` — conectados a servicios reales (`services/Bluetooth.qml`, `services/Network.qml`)

---

## Lock screen

Completo — port visual del theme SDDM "silent", fases 0-6 terminadas. Ver
`lockscreen.md` en la raíz del proyecto para la arquitectura detallada (12+
componentes: `WlSessionLock`, reloj/fecha, avatar + password/fingerprint,
media controls, clima, notificaciones recientes, teclado virtual con estilo
propio, temas custom con sentinels atados a la paleta matugen, integración con
la cadena de idle/screensaver — ver también `idle-screensaver.md`).

---

## Próximo paso inmediato

Quick wins de la última auditoría, sin empezar:

1. Do Not Disturb toggle — complementa el modo caffeine ya existente
2. Clipboard history widget — patrón de referencia ya disponible en `backup/references/end-4/quickshell/Cliphist.qml`

Más grande, sin empezar:

3. `M3Shapes` (plugin C++/Rust) — mayor impacto visual (lock screen), ver `backup/references/quickshell-pending-plugins.md`

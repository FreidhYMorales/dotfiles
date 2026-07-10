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
| Dashboard content | `dashboard/DashboardContent.qml` | 4 cápsulas, scroll sin scrollbar |
| ProfileSection | `dashboard/ProfileSection.qml` | |
| SessionSection | `dashboard/SessionSection.qml` | |
| BatterySection | `dashboard/BatterySection.qml` | |
| PerformanceSection | `dashboard/PerformanceSection.qml` | CircleMetric, CPU/RAM/GPU/Disk |
| MediaSection | `dashboard/MediaSection.qml` | MPRIS completo, selector multi-player |
| DashboardNotificationsSection | `dashboard/DashboardNotificationsSection.qml` | Preview en dashboard |
| Launcher | `launcher/Launcher.qml` | Keyboard exclusive, bottom-center |
| LauncherContent | `launcher/LauncherContent.qml` | Animación multi-stage |
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
3. Keybind cheatsheet overlay — bajo esfuerzo, los keybinds ya están enumerados en `quickshell-vision.md`

Más grande, sin empezar:

4. `M3Shapes` (plugin C++/Rust) — mayor impacto visual (lock screen), ver `backup/references/quickshell-pending-plugins.md`

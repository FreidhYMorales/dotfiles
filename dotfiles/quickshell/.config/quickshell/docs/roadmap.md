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
| CpuWidget | `bar/CpuWidget.qml` | ⚠️ No estaba en visión original |
| RamWidget | `bar/RamWidget.qml` | ⚠️ No estaba en visión original |
| VolumeWidget | `bar/VolumeWidget.qml` | Click abre el OSD de volumen (`Osd.qml`) |
| BatteryWidget | `bar/BatteryWidget.qml` | Solo display |
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
| OSD | `bar/Osd.qml`, `bar/BatteryProfileOsd.qml`, `bar/TrayMenuOsd.qml`, `bar/RecorderModeOsd.qml` | Overlays de volumen/brillo/perfil de energía/tray/grabador, wireados en `shell.qml` |
| Screen recorder | `services/Recorder.qml`, `bar/RecorderWidget.qml`, `bar/RecorderModeOsd.qml` | gpu-screen-recorder (screen/region/window) — ver `recorder.md` |

---

### 🔲 Stubs (solo ícono fijo)

| Elemento | Estado | Pendiente |
|---|---|---|
| `BluetoothWidget` | Ícono 󰂯 fijo | Conectar a servicio BT (Phase 4) |
| `WifiWidget` | Ícono 󰤨 fijo | Conectar a NetworkManager (Phase 4) |

---

## Decisiones pendientes

| Decisión | Opciones | Estado |
|---|---|---|
| ¿`CpuWidget` y `RamWidget` en el bar? | Conservar / Eliminar / Mover al BgApps | Sin decidir |

---

## Phase 4 — Paneles auxiliares

- [x] `OSD` — overlay para cambios de volumen/brillo — implementado (`bar/Osd.qml`), wireado en `shell.qml`
- [ ] `VolumePopout` — panel dedicado con slider de volumen + selector de sink (PipeWire sinks via `pactl list sinks`), a construir desde cero (el contenido standalone previo, `VolumeCard.qml`, se descartó — sin selector de sink y sin uso). El OSD de volumen actual (`Osd.qml`) ya cubre el caso rápido de "cambiaste el volumen", así que esto sería un panel más completo, no un reemplazo.
- [ ] `BluetoothPanel` — lista de dispositivos, toggle on/off, connect/disconnect (via `bluetoothctl`)
- [ ] `NetworkPanel` — lista de redes WiFi, signal, conectar/desconectar (via `nmcli`)
- [ ] `BluetoothWidget` — conectar a servicio real (reemplazar stub)
- [ ] `WifiWidget` — conectar a NetworkManager (reemplazar stub; mostrar SSID + señal)

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

1. Resolver la decisión pendiente sobre CpuWidget/RamWidget
2. Conectar `BluetoothWidget`/`WifiWidget` a servicios reales (reemplazar stubs)
3. Construir `VolumePopout` desde cero si se decide hacerlo (ver Phase 4)

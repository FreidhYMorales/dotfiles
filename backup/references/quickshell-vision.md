# Quickshell — Visión y Diseño

Referencias base: Caelestia (lógica/QML), end-4/ii (lógica/QML), monasm-dots (estilo visual/layout).

---

## Estilo visual

- **Fuente**: monospace/terminal — Monocraft Nerd Font o similar (estilo pixel/terminal)
- **Estética**: TUI-inspired pero no rígido. Pills flotantes, tipografía limpia, mucho espacio negativo
- **Bordes**: mínimos, no marcados. Cero o poco rounding en contenedores principales, pills en status icons
- **Paleta**: dinámica vía matugen → colors.json → FileView en Quickshell
- **Referencia visual directa**: [monasm-dots](https://github.com/Mon4sm/monasm-dots) (EWW, Catppuccin, Monocraft)

---

## Bar

**Posición default:** horizontal, arriba, flotante (con margen).  
**Feature futura:** posición configurable — vertical izquierda, vertical derecha, horizontal abajo.

### Layout (izquierda → derecha)

```
[ Launcher ] [ Workspaces ]          [ Clock ]     [ BgApps ] [ Vol ] [ Bat ] [ BT ] [ WiFi ] [ Dashboard ]
  far-left      left                  center/right              ←————————————— right ————————————————————→
```

| Widget | Posición | Interacción |
|---|---|---|
| App Launcher button | Far left | Click → abre panel launcher |
| Workspaces | Left | Click → cambia workspace |
| Clock (hora ± fecha) | Center o right | Click → calendar widget despliega debajo |
| Background apps | Right | Hover → expande a la izquierda mostrando iconos de apps en bg (Steam, etc.) |
| Volume | Right | Click → volume control popout |
| Battery | Right | % + ícono de carga — solo display, sin interacción |
| Bluetooth | Right | Click → bluetooth panel |
| WiFi | Right | Ícono + intensidad de señal. Click → network manager |
| Dashboard button | Far right | Click → abre panel de control principal |

---

## Paneles y Widgets

### 1. App Launcher
- Se abre desde el botón far-left
- Panel vertical (lado izquierdo), lista scrollable de apps
- Referencia: `menuctl` de monasm

### 2. Calendar Widget (desde clock)
- Click en el reloj → despliega debajo del reloj
- Muestra: hora grande, fecha, calendario mensual
- Referencia: `calendar` de monasm
- **Componente reutilizable** — mismo `CalendarView` que usa el widget de notificaciones

### 3. Widget de Notificaciones / Calendario / Clima
- Panel independiente (no desde el clock — desde su propio trigger)
- Tiene **tab switcher interno** — un botón cambia entre vistas:
  - Tab 1: Notificaciones
  - Tab 2: Calendario (mismo CalendarView reutilizado)
  - Tab 3: Clima
- Las tabs pueden expandirse en el futuro
- Referencia de estructura: tabs de Caelestia dashboard

### 4. Panel de Control Principal (Dashboard)
- Se abre desde el botón far-right
- Panel vertical, lado derecho, scroll vertical
- **Secciones apiladas (no tabs):**
  1. Perfil — avatar, username, uptime
  2. Controles de sesión — power, reboot, suspend, lock, logout
  3. Batería — info detallada (tiempo restante, ciclos, etc.)
  4. Performance — CPU, RAM, GPU (estilo Caelestia performance tab)
  5. Music control — portada, título, artista, progreso, controles (estilo Caelestia media tab)
- Referencia: `usrctl` de monasm (estructura) + tabs de Caelestia (contenido)

### 5. Volume Popout
- Se abre desde el widget de volumen en el bar
- Slider + output selector

### 6. Bluetooth Panel
- Se abre desde el ícono BT
- Lista de dispositivos, toggle, connect/disconnect
- Referencia: Omarchy's BT TUI (estética), Caelestia BT pane (lógica)

### 7. Network Manager Panel
- Se abre desde el ícono WiFi
- Lista de redes, signal strength, conectar/desconectar
- Referencia: `wifi_event` de monasm (estructura), Caelestia network pane (lógica)

---

## Lock Screen

- **Sin dependencia externa** — implementado en Quickshell via `WlSessionLock`
- **Completo, estilo Caelestia** — no minimalista
- **Contenido:**
  - Reloj grande + fecha
  - Avatar + campo de contraseña / fingerprint
  - Media controls (now playing)
  - Info de clima
  - Notificaciones recientes
- Referencia directa: `Lock.qml` de Caelestia

---

## Arquitectura QML (decisiones clave)

### Componentes reutilizables
- `CalendarView` — usado en clock widget Y en notification widget tab. Misma lógica, posición/animación definida por el padre.

### Sistema de colores
- matugen → `~/.config/matugen/colors.json`
- `Colours.qml` singleton con `FileView { watchChanges: true }` leyendo colors.json
- Tokens en snake_case (on_surface, surface_container, etc.) — hay que agregar `#` al asignar a `color` property en QML
- Ver: `references/matugen-pipeline-reference.md`

### IPC con Hyprland
- `IpcHandler` por panel (launcher, dashboard, notifs, lock)
- `CustomShortcut` + Hyprland `global` binds para todos los keybinds
- Patrón de Caelestia: `Visibilities.getForActive()` para afectar solo la pantalla activa

### Visibilities por pantalla
- `PersistentProperties` por monitor (como `DrawerVisibilities` en Caelestia)
- Sobrevive `qs reload`

### Reveal de paneles
- **Click** en el widget del bar → toggle del panel
- **Keybind** → toggle via `CustomShortcut` + `IpcHandler`
- **Sin hover** para abrir paneles (demasiado accidental)
- Excepción: background apps button — hover para expandir (solo muestra iconos, no es panel)

### Posición configurable del bar
- `WlrLayershell` anchor configurable
- Default: `anchors.top + anchors.left + anchors.right` (horizontal top)
- Config value en `shell.json` o equivalente propio
- Futuro: `left`, `right`, `bottom`

---

## Estado actual (junio 2026)

### Módulos completos ✅
- Bar (todos los widgets)
- Dashboard (Profile, Session, Battery, Performance, Media, Notifications)
- Launcher (animación, teclado, hover, tabs)
- Lock screen (PAM real, WlSessionLock, blur)
- Notifications (panel + toast + CalendarTab + WeatherTab)
- CalendarPopout
- OSD (Volume, Brightness, BatteryProfile)
- Todos los servicios

### Pendiente real
1. **`BluetoothPanel` / `NetworkPanel`** — decisión tomada: se quedan como workaround TUI (bluetui / impala en kitty). No se van a implementar como paneles nativos.
2. **`Logo.qml`** — placeholder con glifo Nerd Font. Falta asset SVG real (baja prioridad).

### Resuelto
- **`VolumePopout`** — eliminado. El OSD slider es el mecanismo definitivo.
- **`CustomShortcut`** — implementado via IpcHandler. `Quickshell.Services.GlobalShortcuts` no está disponible en quickshell-git. Shortcuts en `shell.qml` con `IpcHandler { target: "x"; function toggle() { ... } }`. Hyprland Lua: `exec("qs ipc -p /path call <target> toggle")`. Keybinds activos: SUPER+SPACE (launcher), SUPER+D (dashboard), SUPER+N (notifications), SUPER+C (calendar).

### Decisiones pendientes
- `CpuWidget` / `RamWidget` en la barra — no estaban en la visión original, decidir si se quedan
- Ajustes visuales menores en Dashboard y Notifications

---

## Features para después (no v1)

- Posición configurable del bar (vertical left/right, horizontal bottom)
- Workspace groups (ya tenemos el script `wsaction`)
- Visualizador de audio (cava)
- Desktop clock (background layer)

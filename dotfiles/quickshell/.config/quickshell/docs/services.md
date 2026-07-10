# Servicios (`services/`)

Todos son `pragma Singleton` — se importan como namespace, no se instancian.  
Importar con `import "../../services"` (ajustar ruta relativa según profundidad).

---

## `Colours.qml`

Lee `~/.config/matugen/colors.json` con `FileView { watchChanges: true }`.  
Hot-reload automático — la paleta cambia en tiempo real sin reiniciar el shell.

**Uso:**
```qml
color: Colours.m3primary
color: Qt.alpha(Colours.m3surfaceContainerLow, 0.8)
Behavior on color { CAnim {} }   // animación suave en hot-reload
```

**Tokens disponibles (Material 3 completo):**
- Superficies: `m3surface`, `m3surfaceContainer`, `m3surfaceContainerLow`, `m3surfaceContainerHigh`, `m3surfaceContainerHighest`, `m3surfaceVariant`
- Primario: `m3primary`, `m3onPrimary`, `m3primaryContainer`, `m3onPrimaryContainer`
- Secundario: `m3secondary`, `m3onSecondary`, `m3secondaryContainer`, `m3onSecondaryContainer`
- Terciario: `m3tertiary`, `m3onTertiary`, `m3tertiaryContainer`, `m3onTertiaryContainer`
- Superficie: `m3onSurface`, `m3onSurfaceVariant`
- Errores: `m3error`, `m3onError`, `m3errorContainer`
- Bordes: `m3outline`, `m3outlineVariant`

⚠️ Si `colors.json` no existe al arrancar, todos los colores fallan silenciosamente. Correr matugen primero.

---

## `Time.qml`

Timer de 1 segundo. Proporciona todas las variantes de fecha/hora formateadas.

**Propiedades:**
```qml
Time.now        // Date — objeto JS Date completo
Time.hours      // "14"
Time.minutes    // "35"
Time.seconds    // "07"
Time.time24     // "14:35"
Time.timeFull   // "14:35:07"
Time.date       // "Wed 25 Jun"
```

**Reactividad:** `Time.now` cambia cada segundo; las demás propiedades son `readonly` derivadas.

---

## `Battery.qml`

Lee `/sys/class/power_supply/BAT0/`. Refresco cada 30s + **instantáneo** via `udevadm monitor` al conectar/desconectar el cargador.

**Propiedades:**
```qml
Battery.percentage   // int 0-100
Battery.charging     // bool — true si Charging o Full
Battery.health       // int % (energy_full / energy_full_design * 100)
Battery.timeStr      // string: "2h 30m remaining" | "1h 15m to full" | "Full" | "—"
```

**Detalles de implementación:**
- `capProc`: lee `/capacity`
- `statusProc`: lee `/status` → "Charging" / "Discharging" / "Full"
- `healthProc`: corre una vez al inicio, lee `energy_full` + `energy_full_design`. Fallback a `charge_*`
- `timeProc`: calcula tiempo restante con `energy_now / power_now` o `charge_now / current_now`

⚠️ Hardcodeado a `BAT0`. Si el sistema usa `BAT1` u otro nombre, cambiar todas las rutas.

---

## `Audio.qml`

Usa PipeWire/PulseAudio via `pactl` + `wpctl`.

**Propiedades:**
```qml
Audio.volume   // int 0-100
Audio.muted    // bool
```

**Implementación:**
- `subscriber`: `pactl subscribe` corriendo siempre. Al detectar `"on sink #"` dispara `volProc`
- `volProc`: `wpctl get-volume @DEFAULT_AUDIO_SINK@` → parsea `"Volume: 0.75"` y `"[MUTED]"`

⚠️ No tiene funciones de control todavía (subir/bajar/mutear). Agregar cuando se implemente `VolumePopout`.

---

## `SysInfo.qml`

Timer de 2 segundos. Detección de NVIDIA al inicio.

**Propiedades:**
```qml
SysInfo.cpu      // int %
SysInfo.ram      // int %
SysInfo.gpu      // int % (solo si hasGpu)
SysInfo.gpuTemp  // int °C (solo si hasGpu)
SysInfo.disk     // int % (uso de /)
SysInfo.hasGpu   // bool — detectado via "command -v nvidia-smi"
```

**Implementación:**
- `gpuCheckProc`: al inicio, verifica si `nvidia-smi` existe → `hasGpu`
- `cpuProc`: lee `/proc/stat`, calcula `(1 - idle_delta / total_delta) * 100`
- `ramProc`: lee `/proc/meminfo`, `MemTotal` y `MemAvailable`
- `diskProc`: `df / --output=pcent` → parsea el porcentaje
- `gpuProc`: `nvidia-smi --query-gpu=utilization.gpu,temperature.gpu` (solo si `hasGpu`)

⚠️ GPU solo funciona con NVIDIA + nvidia-smi. AMD/Intel necesitaría otro proceso.

---

## `Mpris.qml`

El más complejo. Reactivo explícito — `property var` no trackea sub-propiedades en QML.

**Propiedades expuestas:**
```qml
// Player activo
Mpris.player        // objeto MprisPlayer (interno, no usar directamente)
Mpris.playing       // bool
Mpris.position      // real (segundos)
Mpris.length        // real (segundos)
Mpris.title         // string
Mpris.artist        // string
Mpris.artUrl        // string
Mpris.playerName    // string — display name del player activo
Mpris.hasPlayer     // bool

// Multi-player
Mpris.allPlayers    // var[] — todos los players
Mpris.playerCount   // int — total de players
Mpris.activeIdx     // int — índice del player activo
Mpris.otherPlayers  // var[] de { idx, mp } — todos menos el activo
Mpris.otherCount    // int — playerCount - 1

// Capacidades
Mpris.canNext       // bool
Mpris.canPrev       // bool
```

**Funciones:**
```qml
Mpris.togglePlay()           // toggle play/pause
Mpris.next()                 // siguiente pista
Mpris.previous()             // pista anterior
Mpris.selectPlayer(idx)      // seleccionar player por índice en allPlayers
```

**Patrón de reactividad:**
```qml
// MAL — property var no trackea sub-propiedades:
property var player: Mpris.players.values[0]
Text { text: player.trackTitle }   // no se actualiza

// BIEN — propiedades explícitas + Connections:
property string title: ""
Connections {
    target: root.player
    function onTrackTitleChanged() { root.title = root.player?.trackTitle ?? "" }
}
```

**Refresco:**
- Timer 1s (polling de seguridad)
- `Connections { target: Mpris.players; function onValuesChanged() { _refresh() } }`
- `_refresh()` respeta `activeIdx` si sigue siendo válido; si no, hace auto-select (preferencia al player que esté Playing)

**Display name:**
```qml
// Prioridad: p.identity → p.instanceId.split(".")[0] → "player"
Mpris.playerDisplayName(playerObject)
```

⚠️ `MprisPlaybackStatus` no está exportado en la build del usuario → usar `1` (int) para Playing.  
⚠️ `Mpris.players` es `UntypedObjectModel` → acceder via `.values` (JS array), no `.length`.

**MPD**: requiere `mpd-mpris` (AUR) corriendo: `systemctl --user enable --now mpd-mpris`.

---

## `NotifStore.qml`

Store en memoria de notificaciones recibidas via DBus. El `NotificationServer` en `shell.qml` llama `NotifStore.receive(notif)` por cada notificación.

**Propiedades:**
```qml
NotifStore.notifications   // ListModel — campos: app, summary, body, icon, urgency
NotifStore.unread          // int — contador para el badge del botón
```

**Funciones:**
```qml
NotifStore.receive(notif)    // llamado por NotificationServer
NotifStore.clear()           // borra todo, unread = 0
NotifStore.dismiss(index)    // borra una notificación por índice
```

⚠️ Las notificaciones **no persisten** entre reinicios del shell (in-memory ListModel).  
⚠️ `unread` no decrece al abrir el panel, solo al hacer dismiss o clear.

---

## `Visibilities.qml`

Mutex de paneles. Abrir uno cierra todos los demás.

**Propiedades:**
```qml
Visibilities.launcher        // bool
Visibilities.dashboard       // bool
Visibilities.calendar        // bool
Visibilities.notifications   // bool
```

**Funciones:**
```qml
Visibilities.toggle("dashboard")   // invierte dashboard, cierra el resto
Visibilities.closeAll()            // cierra todos
```

Al agregar un nuevo panel, agregar:
1. `property bool nombrePanel: false`
2. El nombre al array `panels` en `toggle()`

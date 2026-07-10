# Componentes, utils y scripts

---

## Componentes (`components/`)

### `CAnim.qml`

Animación de color estándar. Usar en **todos** los elementos con `color` property para soportar el hot-reload de paleta de matugen.

```qml
// Uso:
Behavior on color { CAnim {} }

// Equivalente a:
Behavior on color { ColorAnimation { duration: 200 } }
```

### `Anim.qml`

Animaciones de entrada/salida para transiciones de layout. Usado en `BgAppsWidget` para el expand al hover.

```qml
Behavior on implicitWidth { Anim { type: Anim.Enter } }
// type: Anim.Enter | Anim.Leave
```

### `StyledRect.qml`

Rectangle con color y radius del sistema de diseño. Helper para casos comunes.

### `qmldir`

Registra los componentes del módulo. Necesario para que QML los encuentre con `import "../../components"`.

---

## Utils (`utils/`)

### `Paths.qml`

Resuelve rutas absolutas relativas a la configuración del shell.

```qml
import "../../utils"

// Uso:
Process { command: ["python3", Paths.scripts + "/list-apps.py"] }
```

**Propiedades:**
```qml
Paths.scripts   // ruta a quickshell/scripts/
```

### `Icons.qml`

Singleton — mapeo de íconos, API compatible con Caelestia. No resuelve rutas de archivo: devuelve nombres de ícono Material Symbols (strings) que otro componente decide cómo pintar.

```qml
import "../../utils"

Icons.getWeatherIcon(code)            // código WMO (Open-Meteo) → nombre de ícono ("clear_day", "rainy", "thunderstorm"...), fallback "air"
Icons.getNotifIcon(summary, urgency)  // heurística por palabras clave en el summary ("reboot", "battery", "update"...), fallback por NotificationUrgency.Critical → "release_alert", si no "chat"
Icons.getVolumeIcon(volume, isMuted)  // volume es 0..1 (no 0..100) — "no_sound" / "volume_up" / "volume_down" / "volume_mute"
Icons.getBatteryIcon(percentage, charging)  // percentage es 0..1 — devuelve nombres tipo "battery_charging_80"/"battery_3_bar"
```

⚠️ `getVolumeIcon`/`getBatteryIcon` esperan fracciones (`0..1`), no porcentajes enteros — distinto de cómo el resto del proyecto maneja volumen/batería (`Audio.volume`/`Battery.percentage` en 0..100). Revisar el call site antes de reusar.

### `CUtils.qml`

Singleton — funciones utilitarias genéricas, API compatible con Caelestia.

```qml
import "../../utils"

CUtils.clamp(value, min, max)     // Math.max(min, Math.min(max, value))
CUtils.lerp(a, b, t)              // interpolación lineal
CUtils.formatDuration(seconds)    // "m:ss" (sin padding en minutos, sí en segundos)
CUtils.toLocalFile(url)           // strips "file://" — para pasar QUrl-like strings a Process/comandos externos
```

### `SysInfo.qml` (`utils/`)

⚠️ No confundir con `services/SysInfo.qml` — este vive en `utils/` y expone **propiedades string** para mostrar (nombre de OS, kernel, uptime formateado), no los porcentajes numéricos de CPU/RAM/GPU/Disk (eso lo tiene el singleton de `services/`).

```qml
import "../../utils"

SysInfo.osName          // "Arch Linux" (fallback si falta /etc/os-release)
SysInfo.osPrettyName    // PRETTY_NAME de /etc/os-release
SysInfo.osId            // ID de /etc/os-release ("arch")
SysInfo.osLogo          // ruta resuelta vía Quickshell.iconPath(), o "" si no hay LOGO en os-release
SysInfo.isDefaultLogo   // true mientras no se resolvió un logo real — para decidir un ícono de respaldo
SysInfo.wm              // XDG_CURRENT_DESKTOP env var, fallback "Hyprland"
SysInfo.user            // USER env var (readonly)
SysInfo.uptime          // "1d 2h 30m" — formateado, se refresca cada 30s
SysInfo.kernel          // /proc/sys/kernel/osrelease
SysInfo.hostname        // /proc/sys/kernel/hostname
```

Lee `/etc/os-release`, `/proc/sys/kernel/osrelease` y `/proc/sys/kernel/hostname` una vez vía `FileView`; `uptime` se recalcula cada 30s con un `Timer` que llama `uptimeFile.reload()`.

---

## Scripts (`scripts/`)

### `list-apps.py`

Parsea archivos `.desktop` para el launcher. Corre como proceso externo desde `LauncherContent`.

**Búsqueda de archivos:**
1. `/usr/share/applications/*.desktop`
2. `~/.local/share/applications/*.desktop`

**Filtros:**
- Excluye entradas con `NoDisplay=true` o `Hidden=true`
- Excluye entradas sin campo `Exec`
- Deduplicación por nombre

**Limpieza de `Exec`:**
Elimina placeholders de freedesktop: `%U`, `%u`, `%F`, `%f`, `%i`, `%c`, `%k`, `%d`, `%D`, `%n`, `%N`, `%v`, `%m`.

**Output:** JSON array por stdout:
```json
[
  {
    "name": "Firefox",
    "exec": "firefox",
    "icon": "/usr/share/icons/hicolor/48x48/apps/firefox.png",
    "description": "Web Browser"
  }
]
```

⚠️ El ícono puede ser una ruta absoluta o un nombre de tema (`"firefox"`). `AppItem` usa `Image { source: appIcon }` — QML resuelve nombres de tema automáticamente en Qt6.

---

## Convenciones de nombres en QML

| Patrón | Significado |
|---|---|
| `_expanded`, `_syncPos()` | Prefijo `_` = privado/interno al componente |
| `Colours.m3*` | Token Material 3 de la paleta |
| `CAnim {}` | Animación de color estándar |
| `HoverHandler { id: hov }` | Handler de hover reutilizable |
| `hov.hovered` | Estado de hover — **solo con `HoverHandler`** (`QQuickHoverHandler`). `HoverHandler` NO tiene `containsMouse`: esa property no existe en el tipo, así que la expresión evalúa a `undefined` (siempre falso) sin tirar ningún error — bug real ya encontrado y corregido en varios componentes del proyecto. |
| `ma.containsMouse` (con `MouseArea { id: ma }`) | Estado de hover — **solo con `MouseArea`**, que sí expone `containsMouse` (requiere `hoverEnabled: true`). Nunca mezclar los dos nombres entre los dos tipos de handler. |
| `Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }` | Expand/collapse estándar |

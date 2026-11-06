# Auditoría de Performance y Arquitectura — 2026-08-11

Auditoría completa, archivo por archivo, de todo `services/`, `components/`, `utils/`, `modules/` y `shell.qml`. Es la segunda tanda de auditoría de este proyecto — la primera (documentada en `docs/roadmap.md`/`docs/gotchas.md`) ya resolvió varios problemas de performance (SysInfo.qml sin fork, Hypr.qml sin polling de capslock, Brightness.qml a 500ms) y de arquitectura (15+ archivos muertos borrados, StateLayer/Capsule/MonitorOsdWindow extraídos). Esta auditoría no vuelve a reportar nada de eso — se enfoca en lo que quedó sin tocar y en lo nuevo que apareció desde entonces (wallpaper picker, idle/screensaver, security/polkit, recorder, keybinds cheatsheet).

## Resumen ejecutivo

- **11 hallazgos totales**: 2 Alto, 6 Medio, 3 Bajo (performance + arquitectura combinados, sin contar código muerto que va en su propia sección).
- **5 archivos de código muerto nuevos** además de los 2 ya conocidos (`SessionSection.qml`, `DashboardNotificationsSection.qml`, que se confirman todavía sin resolver).
- El hallazgo más caro es un `Timer` de 3 segundos en `LockLayouts.qml` que hace fork de un intérprete Python entero cada vez, para siempre, sin gatear por si el lockscreen está visible — el mismo patrón que la auditoría anterior ya había eliminado en `Hypr.qml`, reintroducido acá sin que nadie lo notara.
- El hallazgo de arquitectura más grande es un servicio de clima completo (`services/Weather.qml`, API Caelestia-compatible, 189 líneas) que nadie usa — el panel de clima real (`WeatherTab.qml`) tiene su **propia** implementación paralela e independiente, con otro proveedor y otra tabla de códigos de ícono.
- Se confirma que los 2 archivos muertos ya conocidos siguen sin borrarse, y se encuentra un tercero (`CalendarTab.qml`) que quedó muerto *transitivamente* al morir su único consumidor.

---

## Performance

### 🔴 Alto

#### 1. `services/LockLayouts.qml:41-50` — fork de un intérprete Python completo cada 3s, para siempre, sin gatear por visibilidad

```qml
Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
        queryProc.running = false
        queryProc.running = true
    }
}
```

`queryProc` (línea 23) ejecuta `bash -c "python3 -c \"import json,subprocess; ...\""`, que dentro corre **dos** `hyprctl` (`getoption` + `devices -j`) y parsea el resultado con Python. Esto corre **siempre**, desde que arranca el shell, independientemente de si el lockscreen está visible o no — el propósito de este servicio (mostrar/cambiar el layout de teclado en la pantalla de bloqueo) solo importa mientras `WlSessionLock.locked === true`.

**Por qué importa**: arrancar un intérprete CPython completo (no solo un fork/exec liviano como `cat` o `wpctl`) cada 3 segundos indefinidamente es exactamente el patrón que la auditoría anterior identificó y eliminó en `Hypr.qml` (el comentario de ese archivo lo describe explícitamente: *"a fresh Python interpreter every 3s, forever"*). Este archivo tiene el mismo costo — CPU/batería en reposo, sin ningún beneficio mientras la sesión no está bloqueada.

**Corrección sugerida**: gatear `running`/el `Timer` con un estado "el lock está visible" — `Lock.qml` ya expone `sessionLock.locked` vía `lock` alias; bastaría con importar `Lock`/exponer una property booleana y condicionar `running: root._locked`. Alternativa más agresiva: reemplazar el fork Python por lectura directa de `hyprctl devices -j` + `hyprctl getoption ... -j` como dos `Process` con `SplitParser`/`StdioCollector`, sin subshell ni intérprete extra (patrón que ya usan `Recorder.qml`/`Keybinds.qml` para JSON de hyprctl).

#### 2. `modules/dashboard/ProfileSection.qml:37-51` — proceso `cat /proc/uptime` duplicado, ya resuelto en `SysInfo.qml`

```qml
Process {
    id: uptimeProc
    command: ["cat", "/proc/uptime"]
    stdout: SplitParser { onRead: line => { root._uptime = root._parseUptime(line) } }
}
Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: uptimeProc.running = true }
```

`utils/SysInfo.qml:52-71` ya lee `/proc/uptime` vía `FileView` (cero fork/exec) y lo expone formateado en `SysInfo.uptime`, refrescado cada 30s. `ProfileSection.qml` no lo usa — reimplementa su propio `Process` + parser + Timer de 60s desde cero.

**Por qué importa**: es exactamente el tipo de gasto que la auditoría anterior eliminó a propósito de `SysInfo.qml` (comentario explícito ahí: *"cero fork/exec por tick"*), reintroducido en un archivo distinto sin que nadie lo conectara con el singleton ya existente. Bajo impacto individual (un fork cada 60s), pero es trabajo 100% redundante — dos fuentes de verdad para el mismo dato, con distinto formato de salida (`ProfileSection._parseUptime` vs `SysInfo._parseUptime` en `utils/SysInfo.qml`, casi idénticas pero no iguales).

**Corrección sugerida**: borrar `uptimeProc`/el Timer/`_parseUptime` de `ProfileSection.qml` y usar `SysInfo.uptime` directamente (`import "../../utils"`, ya usado en otros módulos del dashboard).

### 🟡 Medio

#### 3. `services/Bluetooth.qml:14-23` / `services/Network.qml:29-35` — polling de 3s permanente vía fork de CLI

`bluetoothctl show` + `bluetoothctl devices Connected` y `iwctl station ... show` corren cada 3 segundos indefinidamente vía `Process`, sin importar si `BluetoothWidget`/`WifiWidget` están siendo miradas (aunque, a diferencia del caso de `LockLayouts`, estos widgets SÍ están siempre visibles en la barra, así que el polling no es "inútil" como el de LockLayouts). Es consistente con el resto del proyecto (`Battery.qml`, `services/SysInfo.qml` también polean con `Process`), así que no es un anti-patrón nuevo — se deja registrado como oportunidad de mejora futura si se busca reducir consumo en reposo: podría migrarse a un watcher basado en eventos DBus (BlueZ/iwd exponen señales) en vez de polling, similar a como `Battery.qml` ya complementa su polling de 30s con `udevadm monitor` para el caso instantáneo.

#### 4. `services/Notifs.qml` + `services/NotifData.qml` — cada notificación crea el doble de objetos vivos que necesita

`shell.qml:25-26` llama a **ambos** `NotifStore.receive(notif)` y `Notifs.receive(notif)` por cada notificación entrante. `Notifs.receive()` (línea 19) instancia un `NotifData` completo por notificación — que a su vez trae su propio `Timer` recurrente de 5000ms (`NotifData.qml:29-34`, `timeStrTimer`) para actualizar el string relativo ("5m", "2h"). Mientras tanto `NotifStore.qml` guarda la misma información en un `ListModel` plano, sin overhead de Timer por fila.

**Por qué importa**: cada notificación que llega (y que no se cierra) mantiene un `Timer` recurrente propio corriendo indefinidamente además de duplicar el objeto de datos completo — con notificaciones "resident" (`resident: true`, sin auto-expirar) esto puede acumular temporizadores vivos sin límite. Bajo impacto en el uso normal (pocas notificaciones simultáneas), pero es trabajo duplicado por diseño — ver el hallazgo de arquitectura #7 para la causa raíz (dos sistemas de notificaciones paralelos).

#### 5. `modules/launcher/WallpaperCard.qml:51-122` — layer + MultiEffect con máscara por cada card visible del carrusel

Cada `WallpaperCard` (usado en el carrusel de `>wallpaper` y en el mini-carrusel de `>screensaver`) renderiza vía dos `layer.enabled: true` (`cardContent`, `cardMask`) + un `MultiEffect` con `maskEnabled: true` para lograr el recorte de esquinas redondeadas sobre la imagen. Con `pathItemCount: 5`, esto son hasta 5 composiciones enmascaradas en paralelo mientras el carrusel está abierto (bounded, no crece con la cantidad total de wallpapers). No es grave por sí solo, pero es la técnica más cara del proyecto para un simple `radius` — vale la pena confirmar si un `clip: true` + `Rectangle` con `radius` alcanzaría visualmente sin la máscara (el comentario del propio archivo ya explica por qué se descartó `clip: true` solo: no respeta `radius`, deja las esquinas cuadradas de la imagen asomando).

### 🟢 Bajo

#### 6. `layer.enabled: true` en ~10 tarjetas de OSD (`BatteryProfileOsd`, `CalendarPopout`, `Osd` ×2, `RecorderModeOsd`, `TrayMenuOsd`, `NotificationPanelContent`, `NotifToast`, `DashboardContent`, `LockAvatar`) — verificado como patrón intencional y consistente para permitir bordes/clip antialiaseados en rectángulos con esquinas, activo solo mientras cada popup está visible. No es un hallazgo que requiera corrección — se deja documentado como confirmación de que el patrón es deliberado y no accidental.

---

## Arquitectura

### 🔴 Alto

#### 7. `services/Weather.qml` — singleton completo (189 líneas) sin ningún consumidor

```bash
$ grep -rn "Weather\." --include="*.qml" . | grep -v "services/Weather.qml"
# (sin resultados)
```

Implementa geolocalización (`get-location`, GeoClue2/ipinfo.io) + fetch a `api.open-meteo.com` + parseo de forecast diario/horario + mapeo de códigos WMO a íconos, con API "Caelestia-compatible" completa (`Weather.temp`, `.icon`, `.description`, `.forecast`, `.hourlyForecast`, refresco cada 1h). Registrado en `services/qmldir` como singleton. **Cero** archivos del proyecto lo importan ni lo referencian.

#### 8. `modules/notifications/WeatherTab.qml` — reimplementación completa y paralela del clima, con otro proveedor

Este es el panel de clima que **sí** se usa de verdad (instanciado desde `DashboardContent.qml:296`). En vez de consumir `services/Weather.qml`, trae su propio `Process` (`curl -s --max-time 5 wttr.in/?format=j1`, línea 57-58), su propio `Timer` de refresco (1800000ms = 30min, distinto del 1h del singleton muerto), y su propia función `_weatherIcon_from_code()` (líneas 22-34) que mapea códigos **WWO** (el esquema propio de wttr.in: 113, 116, 119, 122...) — un esquema de códigos completamente distinto al **WMO** que usa `Weather.qml`/`Icons.getWeatherIcon()` (0, 1, 2, 3, 45...).

**Por qué importa**: hay dos implementaciones independientes de "traer el clima y mostrarlo" en el mismo proyecto, con dos proveedores distintos (open-meteo vs wttr.in), dos esquemas de códigos de ícono distintos, y dos ciclos de refresco distintos — una está muerta (#7) y la otra es la real. Además de la duplicación de lógica, mantiene dos superficies de red distintas para lo mismo (limita/rompe de forma independiente, dos timeouts distintos, etc.).

**Corrección sugerida**: decidir cuál proveedor se queda. Si es wttr.in (más simple, sin geolocalización previa), borrar `services/Weather.qml` (y evaluar si `get-location` sigue haciendo falta en otro lado). Si se prefiere open-meteo (más datos: forecast horario/diario ya parseados), migrar `WeatherTab.qml` a consumir el singleton en vez de su Process propio.

#### 9. `modules/notifications/CalendarTab.qml` — código muerto transitivo (su único consumidor ya está muerto)

```bash
$ grep -rn "CalendarTab" --include="*.qml" .
modules/dashboard/DashboardNotificationsSection.qml:103:        CalendarTab {
```

El único lugar del proyecto que instancia `CalendarTab.qml` es `DashboardNotificationsSection.qml` — que a su vez es uno de los 2 archivos de código muerto ya conocidos de la auditoría anterior (registrado en `qmldir`, nadie lo instancia). `docs/notifications.md` documenta que `CalendarTab.qml` "hoy se instancian solo desde el dashboard: ... `DashboardNotificationsSection.qml`" sin notar que ese dashboard nunca se instancia — así que este archivo quedó muerto por cascada sin que la auditoría anterior lo detectara (solo marcó el padre directo).

#### 10. `services/Players.qml` — segundo singleton MPRIS paralelo, sin consumidores

```bash
$ grep -rn '\bPlayers\b' --include="*.qml" . | grep -v "services/Players.qml"
# (sin resultados reales — solo "otherPlayers" como substring, no coincide con \b)
```

Expone `Players.list`, `Players.active`, `Players.getArtUrl()` con API "Caelestia-compatible", registrado en `qmldir` como singleton. El servicio MPRIS que realmente usa todo el proyecto es `Mpris.qml` (con su propia lógica de reactividad explícita, multi-player, etc. — ver `docs/services.md`). `Players.qml` es una segunda implementación del mismo dominio que nadie invoca.

#### 11. `components/controls/IconButton.qml` — componente registrado sin ninguna instanciación real

```bash
$ grep -rn '\bIconButton\b' --include="*.qml" . | grep -v "LockIconButton" | grep -v "components/controls/IconButton.qml"
# (sin resultados)
```

Cuidado al re-verificar esto: hay un componente **totalmente distinto** llamado `LockIconButton.qml` en `modules/lock/` (con su propia implementación, sin relación con este) que sí se usa mucho — un grep ingenuo por "IconButton" da falsos positivos. Descartando esos, `components/controls/IconButton.qml` (el "stub" documentado en `components.md` como compatible con la API de Caelestia usada en el lock screen) no tiene ni un solo caller real en today.

### 🟡 Medio

#### 12. Dos sistemas de notificaciones paralelos alimentados por el mismo evento

`shell.qml:24-27`:
```qml
onNotification: notif => {
    NotifStore.receive(notif)
    Notifs.receive(notif)
}
```

Cada notificación entrante se guarda **dos veces**, en dos estructuras de datos completamente independientes:
- `NotifStore.qml` — `ListModel` plano, consumido por `NotificationsTab.qml` (panel completo) y `NotificationButton.qml` (badge de no leídas).
- `Notifs.qml` — lista de objetos `NotifData` (QtObject dinámico + Timer propio cada uno, ver hallazgo de performance #4), consumido por `NotifToast.qml` (toast emergente) y `DashboardContent.qml` (preview de notificación activa en el dashboard).

No hay ninguna razón funcional visible por la que el toast/dashboard no puedan leer de `NotifStore` igual que el panel — son la misma información (`app`/`summary`/`body`/`icon`/`urgency`) con nombres de campo levemente distintos (`app` vs `appName`, por ejemplo). Mantenerlos separados obliga a que cualquier cambio de comportamiento de notificaciones (dismiss, urgencia, expiración) se replique en dos lugares.

**Corrección sugerida**: unificar en una sola fuente — lo más simple es que todo el mundo lea de `NotifStore` (ya es más liviano, sin Timer por ítem) y agregar a `NotifStore` lo que hoy solo tiene `Notifs`/`NotifData` (campo `popup`/`closed`/`expireTimeout` si hace falta para el toast).

#### 13. `modules/bar/Osd.qml` — ~130 líneas de slider duplicado que el propio proyecto ya extrajo a un componente

`Osd.qml:135-222` (`volSlider`) y `Osd.qml:251-316` (`brightSlider`) son dos copias casi idénticas de track+fill+thumb+MouseArea con matemática de `travel`/`thumbX`. El comentario de cabecera de `components/controls/Slider.qml` lo dice explícitamente: *"extracted from the volume/brightness sliders duplicated inline in modules/bar/Osd.qml... Osd.qml's own two copies are left untouched — this doesn't replace them"*. Es decir, la duplicación es conocida y fue una decisión consciente en su momento (no romper un flujo que funcionaba), pero sigue siendo ~130 líneas redundantes que ya tienen un reemplazo disponible y probado (el mismo componente ya se usa en otro lugar del proyecto... aunque, ver hallazgo de código muerto: en realidad `Slider.qml` terminó sin ningún caller real tampoco, ver más abajo). Vale la pena revisar si migrar `Osd.qml` a `Slider.qml` de una vez, ya que además resolvería el hallazgo de código muerto de `Slider.qml`.

#### 14. Guard "movimiento real del mouse" duplicado en 3 archivos

El bloque de ~20 líneas que distingue un movimiento real de mouse del "pointer enter" sintético de Wayland (armed/baseX/baseY/moveThreshold de 4px) aparece copiado casi textual en:
- `modules/launcher/LauncherContent.qml:539-561` (`wallpaperMoveTracker`)
- `modules/launcher/ScreensaverForm.qml:299-321` (`wallpaperMoveTracker`, mismo nombre de id)
- `modules/lock/LockIdle.qml:230-243` (`idleMouseArea`, misma lógica embebida directo en el MouseArea de detección de idle)

Los tres resuelven exactamente el mismo problema (documentado en `idle-screensaver.md` gotcha #7/#8 y en los comentarios de cada archivo) con el mismo umbral (4px). Buen candidato a extraer como un pequeño componente reusable (`components/RealMoveGuard.qml`, o una `MouseArea` wrapper con una señal `onRealMove()`).

#### 15. Lista de 5 acciones de power duplicada verbatim en 3 archivos

El array `[{icon:"󰐥", cmd:["systemctl","poweroff"]}, {icon:"󰜉", cmd:[...reboot]}, {icon:"󰤄", cmd:[...suspend]}, {icon:"󰌾", cmd:[...lock via qs ipc]}, {icon:"󰍃", cmd:["hyprctl","dispatch","hl.dsp.exit()"]}]` aparece copiado, mismos íconos y mismos comandos, en:
- `modules/dashboard/ProfileSection.qml:16-24` (`_powerButtons`)
- `modules/powermenu/PowerMenuOsd.qml:109-115` (`pill.buttons`)
- `modules/dashboard/SessionSection.qml:15-21` (ya muerto, pero ilustra que el patrón se copió 3 veces antes de que ese archivo quedara huérfano)

Cambiar un ícono, agregar una acción (ej. "restart display manager"), o corregir un comando (como ya pasó una vez con el bridge Lua de Hyprland, ver `docs/architecture.md`) requiere tocar cada copia por separado sin garantía de que queden sincronizadas. Candidato a `utils/PowerActions.qml` (array compartido) o extender `services/Keybinds.qml` con esta info.

#### 16. Patrón "ícono con hover+scale 1.35" repetido en ~10 widgets de la barra

`CpuWidget`, `RamWidget`, `BatteryWidget`, `BluetoothWidget`, `WifiWidget`, `RecorderWidget`, `VolumeWidget`, `ClockWidget`, `DashboardButton`, `LauncherButton`, `NotificationButton` repiten, cada uno, el mismo bloque:
```qml
Text { ...; scale: root.active ? 1.35 : 1.0; transformOrigin: Item.Center
       Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
```
junto con el `Rectangle` de fondo (`radius: Style.cornerRadius; color: hov.hovered ? ... : m3surfaceContainerHigh`). Es una repetición consistente (buena señal de convención estable) pero también ~10 copias del mismo bloque de ~15 líneas — candidato a un `BarIcon.qml`/`BarPillIcon.qml` parametrizado por ícono+color+acción.

### 🟢 Bajo

#### 17. `modules/bar/BarContent.qml` — 12 bloques de divisor `Rectangle` idénticos

El separador de 2px entre widgets dentro de las píldoras de la barra (`Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)`) se repite 12 veces verbatim en `BarContent.qml` (entre cada par de widgets en `leftPillRow`/`midPillRow`/`pillRow`). Candidato trivial a un `PillDivider.qml` de 3 líneas.

#### 18. `Style.fontFamilyMono` y `Style.radius()` — declaradas, documentadas como "sin uso todavía", confirmado sin consumidores

`docs/services.md` ya lo documenta explícitamente. Confirmado que sigue siendo así — no es urgente, solo deuda técnica ya reconocida.

#### 19. Umbrales de batería inconsistentes entre `BatteryWidget.qml` (barra) y `BatterySection.qml` (dashboard)

`BatteryWidget.qml:71-74` usa cortes en 80/50/20 para elegir ícono; `BatterySection.qml:12-24` (`batteryIcon()`) usa cortes de a 10 (90/80/70/60/50/40/30/20/10). No es un bug — son widgets visualmente distintos (uno con 5 estados, otro con 10 iconos de a 10%) — pero es una inconsistencia de convención que alguien editando "el ícono de batería" del proyecto podría no esperar tener que tocar en dos lugares con lógicas distintas.

---

## Código muerto pendiente

### Ya conocidos (confirmados, siguen sin resolver)

| Archivo | Estado |
|---|---|
| `modules/dashboard/SessionSection.qml` | Registrado en `qmldir`, cero instanciaciones. Confirmado de nuevo. |
| `modules/dashboard/DashboardNotificationsSection.qml` | Registrado en `qmldir`, cero instanciaciones. Confirmado de nuevo. |

### Nuevos encontrados en esta auditoría

| Archivo | Motivo |
|---|---|
| `services/Weather.qml` | Singleton completo (189 líneas), cero referencias en todo el proyecto (ver hallazgo #7). |
| `services/Players.qml` | Singleton MPRIS paralelo a `Mpris.qml` (el real), cero referencias (ver hallazgo #10). |
| `components/controls/IconButton.qml` | Registrado en `qmldir`, cero instanciaciones reales — no confundir con `LockIconButton.qml`, que es otro componente y sí se usa (ver hallazgo #11). |
| `components/controls/Slider.qml` | Cero instanciaciones (`grep '^\s*Slider\s*{'` sin resultados). Ya documentado en `idle-screensaver.md` como "no usado en el form pero queda en components/", nunca marcado formalmente para borrar. |
| `modules/notifications/CalendarTab.qml` | Muerto transitivamente — su único consumidor (`DashboardNotificationsSection.qml`) también está muerto (ver hallazgo #9). |

---

## Tabla resumen

| Archivo | Línea | Severidad | Categoría | Descripción corta |
|---|---|---|---|---|
| `services/LockLayouts.qml` | 41-50 | Alto | Performance | Timer 3s permanente, fork de intérprete Python completo, sin gatear por visibilidad del lock |
| `modules/dashboard/ProfileSection.qml` | 37-51 | Alto | Performance | `cat /proc/uptime` propio, duplica `SysInfo.uptime` ya existente (sin fork) |
| `services/Bluetooth.qml` / `services/Network.qml` | 14-23 / 29-35 | Medio | Performance | Polling 3s permanente vía fork CLI (consistente con el resto, oportunidad de migrar a eventos) |
| `services/Notifs.qml` / `services/NotifData.qml` | 19 / 29-34 | Medio | Performance | Cada notificación crea un Timer recurrente propio además del objeto duplicado |
| `modules/launcher/WallpaperCard.qml` | 51-122 | Medio | Performance | layer+MultiEffect con máscara por card visible del carrusel (bounded, pero técnica cara para un `radius`) |
| Varios OSD (10 archivos) | — | Bajo | Performance | `layer.enabled: true` consistente — confirmado intencional, no requiere acción |
| `services/Weather.qml` | todo el archivo | Alto | Arquitectura | Singleton completo sin ningún consumidor |
| `modules/notifications/WeatherTab.qml` | 22-34, 56-80 | Alto | Arquitectura | Reimplementación paralela del clima, otro proveedor/otro esquema de códigos que el singleton muerto |
| `modules/notifications/CalendarTab.qml` | todo el archivo | Alto | Arquitectura | Código muerto transitivo (único consumidor ya muerto) |
| `services/Players.qml` | todo el archivo | Alto | Arquitectura | Segundo singleton MPRIS paralelo a `Mpris.qml`, sin consumidores |
| `components/controls/IconButton.qml` | todo el archivo | Alto | Arquitectura | Registrado en qmldir, cero instanciaciones reales |
| `shell.qml` + `services/Notifs.qml` + `services/NotifStore.qml` | 24-27 | Medio | Arquitectura | Dos sistemas de notificaciones paralelos alimentados por el mismo evento |
| `modules/bar/Osd.qml` | 135-222, 251-316 | Medio | Arquitectura | ~130 líneas de slider duplicado pese a tener `Slider.qml` ya extraído |
| `LauncherContent.qml` / `ScreensaverForm.qml` / `LockIdle.qml` | varias | Medio | Arquitectura | Guard de "movimiento real del mouse" duplicado en 3 archivos |
| `ProfileSection.qml` / `PowerMenuOsd.qml` / `SessionSection.qml` | varias | Medio | Arquitectura | Lista de 5 acciones de power duplicada verbatim en 3 archivos |
| ~10 widgets de la barra | varias | Medio | Arquitectura | Patrón ícono+hover+scale 1.35 repetido, candidato a componente compartido |
| `modules/bar/BarContent.qml` | 12 bloques | Bajo | Arquitectura | Divisor Rectangle repetido 12 veces verbatim |
| `services/Style.qml` | 11, 23-25 | Bajo | Arquitectura | `fontFamilyMono`/`radius()` confirmadas sin consumidores (ya documentado) |
| `BatteryWidget.qml` vs `BatterySection.qml` | — | Bajo | Arquitectura | Umbrales de ícono de batería inconsistentes entre barra y dashboard |

# Salvapantallas + auto-bloqueo + auto-suspensión + modo caffeine

Cadena de inactividad completa: salvapantallas (imagen o video) → bloqueo real
del equipo (sin pedir contraseña todavía) → contraseña requerida al primer
input pasado un tiempo extra → suspensión si no se toca nada. Botón de modo
caffeine (taza vacía/llena) en el popup del OSD de perfiles de energía.

## Por qué no se usa hypridle

`~/.config/hypr/hypridle.conf` existe pero el binario `hypridle` no está
instalado en este sistema, y su config apuntaba a `hyprlock` (externo), no al
lockscreen propio. Se implementó nativo con los bindings Wayland de
Quickshell (`import Quickshell.Wayland` → `IdleMonitor`/`IdleInhibitor`,
protocolos `ext-idle-notify-v1`/`ext-idle-inhibit-v1`) en vez de reactivar y
reconciliar una herramienta externa — mismo criterio que con el wallpaper
picker (ver `wallpaper-theming.md`).

## Arquitectura (versión final, tras iterar)

**Decisión clave: el bloqueo real (`WlSessionLock.locked = true`) se dispara
ya al llegar al umbral del salvapantallas, no en un umbral separado
posterior.** No es una relajación de seguridad — `LockSurface.qml` mantiene
oculto el prompt de contraseña y libera sin pedirla mientras no haya pasado
el tiempo de gracia extra configurado. Este diseño es la respuesta a una
limitación real de `ext-session-lock-v1`: una vez bloqueada la sesión, la
superficie exclusiva del compositor tapa CUALQUIER otra superficie sin
excepción, incluida una superficie de salvapantallas separada. La primera
versión usaba dos superficies distintas (un `Overlay` para el salvapantallas,
después el lock real) y el video/imagen se reiniciaba desde cero en el
traspaso — se veía como un corte/flicker. Bloqueando temprano y renderizando
el salvapantallas DENTRO de `LockSurface.qml` todo el tiempo, hay un solo
pipeline de media que nunca se reinicia. `modules/screensaver/` (el módulo
separado de la primera versión) se eliminó por completo.

- **`services/IdleManager.qml`** (singleton) — timeouts y fuente del
  salvapantallas persistidos (`~/.local/state/quickshell/idle.json`, mismo
  patrón que `Wallpapers.qml`/`Colours.qml`). `caffeineMode` NO persiste
  (arranca apagado siempre — es estado de sesión, no preferencia).
  - `screensaverTimeoutMin` (3): al cumplirse, `screensaverMonitor` dispara
    `qs ipc call lock lockFromIdle` — bloquea YA, muestra el salvapantallas.
  - `lockTimeoutMin` (5): tiempo EXTRA (mismo punto de referencia que el
    anterior) antes de que un input real exija contraseña en vez de liberar
    gratis. Expuesto como `lockGraceElapsed` — ver gotcha de la carrera más
    abajo, es un LATCH, no una lectura directa de `lockMonitor.isIdle`.
  - `suspendTimeoutMin` (15): etapa independiente, `systemctl suspend`.
  - `effectiveScreensaverSource`: `screensaverUseWallpaper` (true) espeja
    `Wallpapers.current` (el wallpaper de escritorio); si es false, usa
    `screensaverPath` (ruta separada — sin UI todavía, solo editable a mano
    en el JSON, la UI queda para el widget de configuración futuro).
- **`modules/lock/LockSurface.qml`** — ahora tiene un modo
  `useScreensaverBg` (`lockedViaIdle && !revealed`): mientras está activo,
  el fondo es `IdleManager.effectiveScreensaverSource` (no el fondo
  configurado del theme SDDM), sin blur/brillo/saturación del theme (valores
  neutros), y `LockIdle` oculta reloj/fecha/mensaje (`contentVisible: false`)
  y el cursor (`Qt.BlankCursor`) — solo se ve la imagen/video puro, igual que
  el salvapantallas de antes de bloquear. El primer input real revela según
  `IdleManager.lockGraceElapsed`: si NO pasó el tiempo de gracia, libera sin
  contraseña (`root.lock.locked = false`); si ya pasó (o es un lock manual,
  `lockedViaIdle` false), revela el prompt real (`revealed = true`).
- **`modules/lock/Lock.qml`** — `lockedViaIdle: bool` (se pone en `true` solo
  vía la IPC nueva `lockFromIdle()`; `lock()` sigue siendo el manual sin
  cambios). Se resetea a `false` en `onLockedChanged` cuando se desbloquea.
- **`modules/lock/LockIdle.qml`** — `contentVisible: bool` (nuevo) oculta
  reloj/fecha/mensaje sin tocar la detección de input (que sigue siempre
  activa). El cursor se pone `Qt.BlankCursor` mientras `!contentVisible`.
- **`modules/background/Background.qml`** — aloja el único `IdleInhibitor`
  del proyecto (`enabled: IdleManager.caffeineMode`), porque necesita una
  ventana SIEMPRE mapeada para funcionar — ver gotcha del flicker de
  caffeine más abajo.
- **`modules/bar/BatteryProfileOsd.qml`** — botón de taza (llena/vacía)
  al lado del selector de perfil de energía, alterna `IdleManager.caffeineMode`.

## Gotchas encontrados (importantes para no repetir)

1. **`IdleMonitor.timeout` está en SEGUNDOS, no milisegundos.** La
   documentación/qmltypes no lo deja claro a simple vista; confirmado leyendo
   el header fuente real de Quickshell (`monitor.hpp`): *"The amount of time
   in seconds the idle monitor should wait..."*. Multiplicar minutos por
   60000 (asumiendo ms) deja timeouts de horas en vez de minutos — el bug
   más silencioso de toda esta feature, no tira error, simplemente nunca
   dispara en una prueba corta. Multiplicar por `60`, no `60000`.
2. **Cualquier singleton de Quickshell que use `Component.onCompleted`
   necesita `import QtQuick` explícito**, aunque ya importe
   `Quickshell`/`Quickshell.Wayland`. Sin eso, el motor QML tira
   `Non-existent attached object` apuntando a la línea de
   `Component.onCompleted` — el mensaje no da ninguna pista de que el
   problema es un import faltante.
3. **`IdleInhibitor.window` necesita una ventana SIEMPRE mapeada** — no
   puede vivir en la ventana del salvapantallas si esa ventana solo se hace
   visible cuando `isIdle` ya es true (problema del huevo y la gallina: el
   inhibidor recién "cuenta" una vez mapeado, pero se necesita que cuente
   ANTES de que se mapee para evitar el flicker). Confirmado empíricamente:
   con el inhibidor en la ventana del salvapantallas, activar caffeine
   producía un parpadeo del salvapantallas de ~150-180ms cada ciclo del
   timeout (se mapeaba, el inhibidor recién ahí frenaba, se desmapeaba, y
   así en bucle). Se resolvió moviendo el `IdleInhibitor` a
   `Background.qml`, cuya ventana está mapeada permanentemente.
4. **`MultiEffect.brightness`/`saturation` van de -1.0 a 1.0, con 0.0 =
   "sin cambios"** — NO 1.0. Usar 1.0 pensando que era "normal/completo"
   (como opacity o CSS saturate(1)) satura la imagen a blanco puro.
   Confirmado visualmente ("pantalla en blanco" al activar el fondo del
   salvapantallas en el lock).
5. **`ext-session-lock-v1` tapa TODO sin excepción una vez bloqueado** —
   ninguna superficie `WlrLayer.Overlay` propia puede sobrevivir visualmente
   a un lock real, sin importar cómo se bindee su `visible`. Esto invalidó
   el diseño original (salvapantallas como módulo separado que "sigue
   corriendo por detrás") y forzó la arquitectura final: bloquear temprano y
   renderizar el salvapantallas DENTRO de `LockSurface.qml`.
6. **Carrera async al decodificar video como imagen** — al cambiar de fuente
   (wallpaper de video ↔ fondo del theme), por un instante `isVideo` puede
   ir un tick atrasado respecto a `bgSource`, y el `Image` intenta decodificar
   el `.mp4` como imagen, falla, y el `onStatusChanged` original marcaba
   `bgFailed = true` permanentemente (perdiendo el video para siempre en esa
   sesión de lock). Peor: el error es ASÍNCRONO — puede llegar después de
   que `bgSource`/`isVideo` YA cambiaron de nuevo (ej. justo al revelar el
   prompt de contraseña), así que comparar contra el `root.isVideo` ACTUAL
   en el momento del error es insuficiente (ya cambió). Fix: comparar contra
   el `source` real del propio `Image` en el momento del fallo
   (`background.source`, no `root.bgSource`), inmune a en qué haya mutado el
   estado externo mientras tanto.
7. **El "primer `positionChanged`" tras mapear una superficie no es
   movimiento real.** Wayland manda un evento de "pointer enter" con la
   posición actual del cursor en cuanto una superficie nueva gana foco de
   puntero, y `MouseArea` lo reporta igual que un movimiento real — sin
   guardia, el prompt se revelaba instantáneamente al bloquear, sin dejar
   ver nunca el salvapantallas. Fix: guardar una posición base en el primer
   evento (ignorarlo), y solo dsiparar en eventos posteriores.
8. **Ese guardado de posición base tampoco alcanza solo** — jitter de mouse
   normal (polling del touchpad, redondeo, lo que sea) sigue generando
   diffs de 1px contra la base, dsiparando el "revelar" casi instantáneo
   igual. Fix: exigir una distancia mínima (`moveThreshold`, 4px) contra la
   base, no cualquier diferencia.
9. **La condición de carrera más sutil: el propio input que dispara el
   chequeo también resetea lo que se está chequeando.** `lockGraceElapsed`
   originalmente era una lectura directa de `lockMonitor.isIdle`. Pero el
   input real que dispara `loginRequested()` es LA MISMA actividad que
   resetea `lockMonitor.isIdle` a `false` — confirmado en el log: el
   `isIdle=false` del monitor llegaba una fracción de milisegundo ANTES que
   el chequeo en `LockSurface`, así que el chequeo SIEMPRE veía `false`, sin
   importar cuánto tiempo de gracia hubiera pasado realmente. Resultado
   observado: nunca pedía contraseña, se liberaba solo (y como el
   wallpaper de escritorio coincide con el del salvapantallas, visualmente
   parecía "seguir en modo salvapantallas para siempre"). Fix: convertir
   `lockGraceElapsed` en un LATCH (`property bool` normal, se pone `true`
   una vez en `lockMonitor.onIsIdleChanged` y se queda así hasta el próximo
   ciclo de bloqueo) en vez de un valor derivado que se resetea con la misma
   actividad que lo consulta.
10. **Carrera de arranque intermitente: algunas instancias nuevas nunca
    disparaban `isIdle`, otras sí, con el mismo código.** Las properties de
    timeout arrancan en su default hardcodeado (3/5/15 min) y recién toman
    el valor persistido una vez que el `FileView` termina de cargar — si
    `IdleMonitor.enabled` ya es `true` desde el arranque, el objeto de
    idle-notify subyacente se crea contra el timeout DEFAULT, y cuando el
    valor persistido lo cambia un instante después, no está garantizado que
    se reconstruya correctamente. Fix: gatear `enabled` también con
    `_restored` (el flag que ya existía para saber si el estado terminó de
    cargar), así el monitor nunca se crea contra un valor que va a cambiar
    en el siguiente tick.
11. **`qs -p <config>` sin `-n`, corrido desde un entorno sandboxeado
    distinto a la sesión gráfica real, arranca una instancia nueva en vez de
    conectarse a la existente** — útil para chequear errores de QML rápido
    sin tocar la instancia real del usuario (siempre que se envuelva en
    `timeout Ns` y se confirme después que no quedó huérfana con
    `qs list --all`).
12. **El auto-reload por cambios de archivo (file-watch) puede quedar
    "pegado"** en una instancia particular tras varias ediciones rápidas
    seguidas — dejó de detectar cambios de un archivo específico sin error
    visible. No se encontró causa raíz confirmada (sospecha: reemplazo de
    inodo en alguna edición rompiendo un watch específico). Mitigación
    práctica: si dos ediciones seguidas no generan `"Reloading
    configuration..."` en el log en varios segundos, matar y relanzar la
    instancia en vez de seguir esperando al watcher.
13. **Se intentó y se DESCARTÓ una animación de entrada para el
    salvapantallas** (fade-in, luego wipe top-to-bottom, luego slide-in tipo
    OSD) — documentado por si se retoma más adelante, para no repetir los
    mismos tropiezos:
    - `WlSessionLockSurface` NO tiene `opacity` ni geometría escribible
      (`visible`/`width`/`height` son de solo lectura) — cualquier animación
      tiene que vivir en un `Item` hijo envolvente, no en la superficie
      misma.
    - Animar `height`/`y` con un `NumberAnimation` que usa `to: root.height`
      (u otra expresión) CAPTURA ese valor una sola vez al arrancar — si
      `root.height` todavía es `0` en ese instante (geometría real no
      asentada aún), anima de 0 a 0, sin movimiento visible, silenciosamente.
      Fix (parcial): animar un progreso `0..1` aparte y multiplicar por el
      valor ACTUAL de `root.height` en un binding reactivo, no capturarlo
      una vez.
    - Un `Item` con `anchors.fill: parent` Y un binding manual de `y` en el
      mismo elemento entran en conflicto — el sistema de anchors gana
      siempre, fijando `y` en 0 pase lo que pase con el binding manual.
      Confirmado con log: `y` se quedaba en `0` durante toda la animación
      pese a que el progreso sí avanzaba.
    - El fondo negro durante la transición NO se puede evitar poniendo la
      superficie del lock en `color: "transparent"` — `ext-session-lock-v1`
      es un protocolo de seguridad, Hyprland no compone nada detrás de la
      superficie de lock sin importar su alpha. Confirmado empíricamente
      (seguía negro con `transparent`).
    - **El bug más caro de diagnosticar**: si `LockIdle` (que tiene el
      `MouseArea` de detección de movimiento) queda ANIDADO dentro del
      `Item` que se anima (ej. un slide-in), el `MouseArea` se mueve junto
      con el contenido — y como `mouseX`/`mouseY` son coordenadas LOCALES,
      un cursor perfectamente quieto "se mueve" en el sistema de
      coordenadas local solo porque el contenedor se desliza por debajo.
      Esto disparaba `loginRequested()` casi de inmediato, liberando el
      lock sin contraseña a los ~150ms de haberse bloqueado — visible como
      un "flicker" y "el screensaver no se activa". Si se retoma la
      animación, `LockIdle`/`LockAuth` (la capa de input) tienen que quedar
      SIEMPRE fuera de cualquier contenedor que se anime, fijos y a pantalla
      completa desde el primer frame.
    - Decisión final del usuario: no vale la pena la complejidad adicional
      (más una animación inversa simétrica para cuando se revela la
      contraseña) para el beneficio cosmético — se dejó la transición
      instantánea (sin animación), que funciona correctamente.
14. **`lockMonitor` y `screensaverMonitor` miden el mismo reloj de
    inactividad (tiempo desde la última actividad real), NO son etapas
    secuenciales** — si se configura `lockTimeoutMin <= screensaverTimeoutMin`
    (posible desde que existe el panel `>screensaver`, antes solo se editaba
    el JSON a mano con valores ya coherentes), los dos `IdleMonitor` disparan
    `onIsIdleChanged` casi en el mismo tick, en orden no garantizado.
    `screensaverMonitor` resetea `lockGraceElapsed = false` mientras
    `lockMonitor` lo pone en `true` — si el reset corre después, queda
    pegado en `false` para siempre (no hay otra transición false→true sin
    actividad real de por medio), y el salvapantallas se queda mostrado
    indefinidamente sin pedir nunca la contraseña. **Fix**: `lockMonitor` ya
    no usa `lockTimeoutMin*60` en crudo — usa `Math.max(lockTimeoutMin*60,
    screensaverTimeoutMin*60 + 5)`, garantizando que siempre dispare al
    menos 5 segundos real después del salvapantallas, sin importar qué
    combinación de valores se configure.
15. **El sentinel `"wallpaper"` del lockscreen (`custom.conf`) y
    `IdleManager.effectiveScreensaverSource` eran el mismo valor por
    casualidad, no por diseño** — antes de que existiera el panel
    `>screensaver`, `effectiveScreensaverSource` siempre era igual a
    `Wallpapers.current` (no había forma de que el salvapantallas usara una
    imagen distinta), así que reusarlo para el sentinel "el fondo del
    lockscreen debe coincidir con el wallpaper" era inofensivo. En cuanto el
    panel permitió `screensaverUseWallpaper: false` con una ruta propia, el
    lockscreen (una vez revelado el prompt) empezó a mostrar la imagen del
    salvapantallas en vez del wallpaper real. **Fix**: `LockSurface.qml`
    distingue los dos casos — durante la fase idle sin revelar
    (`useScreensaverBg`) sí muestra `effectiveScreensaverSource`; el
    sentinel `useWallpaperBg` en sí mismo ahora resuelve directo a
    `Wallpapers.current`, nunca al del salvapantallas.

## Panel de configuración (`>screensaver`, agregado después)

Comando del launcher, mismo patrón que `>wallpaper`/`>theme` — expone los 5
campos de `IdleManager.qml` (timeouts de salvapantallas/bloqueo/suspensión,
0 = desactivado; toggle "mismo fondo que el escritorio" vs. uno distinto,
con picker propio reusando el carrusel de `>wallpaper` pero escribiendo en
`IdleManager.screensaverPath`, nunca en `Wallpapers.preview()`/`commit()`).
Incluye un botón de previsualización en una ventana completamente aparte
(`modules/screensaver/ScreensaverPreview.qml`) que nunca toca
`Lock`/`WlSessionLock` — es la única forma de ver el salvapantallas sin
bloquear la sesión real. Primeros componentes reutilizables de slider/toggle
del proyecto (`components/controls/Slider.qml`/`Toggle.qml`, antes solo
duplicados a mano en `Osd.qml`). Los dos gotchas #14 y #15 de arriba se
encontraron probando este panel en vivo. Detalle completo: memoria
`screensaver_settings_panel.md`, engram `quickshell/screensaver-settings-panel`,
`quickshell/idle-lock-timeout-race`, `quickshell/lockscreen-wallpaper-sentinel-fix`.

## Pendientes / no incluido

- Animación de entrada del salvapantallas — intentada y descartada por
  complejidad/beneficio, ver gotcha #13 si se quiere retomar. La opción más
  prometedora que no se llegó a probar: un módulo `Overlay` SEPARADO del
  lock (sin la restricción de fondo negro de `ext-session-lock-v1`) que
  corre la animación primero y recién al terminar dispara el bloqueo real —
  para video, mostrar un frame estático inicial (mismo patrón de extracción
  que ya usa `Colours.qml`/`Wallpapers.qml`) durante la animación y arrancar
  el video real recién en el `LockSurface`.
- El botón "Suspend" manual del dashboard (`ProfileSection.qml`) no bloquea
  antes de suspender — fuera de alcance de este pedido.
- `hypridle.conf` se deja como está (huérfano, no corre).

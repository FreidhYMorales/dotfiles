# Screen recorder (gpu-screen-recorder)

Grabación de pantalla nativa vía `gpu-screen-recorder`, con tres modos
(screen/region/window) elegibles desde un OSD de la bar. Widget con
indicador de tiempo transcurrido mientras graba, notificación al terminar.

**Estado (2026-08-17): funcional de punta a punta para screen y region**,
verificado en vivo en la ThinkPad (mp4 real, VAAPI h264 + audio, muxeo
correcto vía SIGINT; region con selección real por click-arrastre tras
el fix del gotcha #6) — `window` comparte el mismo pipeline y el mismo
código de arranque, sin verificación empírica dedicada todavía (ver
Pendientes). Mode selection y el toggle de audio se movieron del
right-click OSD de la barra a una sección nueva del dashboard
(`RecorderSection.qml`) — ver Arquitectura.

**Gotcha encontrado y resuelto esta sesión**: `gpu-screen-recorder-git`
(AUR, instalado 27 jul) estaba roto — `libavcodec.so.62`/`.60`/`.6`/`.11`
no encontradas — porque un `pacman -Syu` el 13 ago subió `ffmpeg` a 9.0.1
(sonames `.63`), y el binario AUR seguía linkeado contra las libs viejas.
Fix: `yay -S gpu-screen-recorder-git --rebuild` (bump a
`6.0.0.r6.g20dbed9`) + `sudo pacman -U` de los paquetes generados. Cualquier
paquete `-git`/AUR que linkee contra ffmpeg puede romperse de la misma
forma en el próximo `-Syu` que bump ffmpeg — no hay forma de detectarlo
sin correr el binario.

## Por qué gpu-screen-recorder y no wf-recorder

Este proyecto corre en dos máquinas distintas (desktop NVIDIA, Thinkpad solo
Intel) y `gpu-screen-recorder` auto-detecta el vendor de GPU y elige el
encoder correcto (NVENC en la NVIDIA, VAAPI en el Intel) sin config por
máquina. `wf-recorder` hubiera necesitado flags de encoder distintos por
equipo — mismo criterio de "evitar reconciliar config específica de máquina"
que otras decisiones del proyecto (ver `idle-screensaver.md`, sección de por
qué no hypridle).

## Arquitectura

- **`services/Recorder.qml`** (singleton) — todo el estado y los `Process`
  que hablan con `gpu-screen-recorder`/`slurp`/`hyprctl`.
  - `recording` (bool), `mode` (`"screen"|"region"|"window"` — doble uso:
    preferencia para el próximo `start()` Y, mientras graba, en qué modo
    arrancó), `systemAudioEnabled`/`micAudioEnabled` (bool, independientes),
    `elapsedSeconds` (int, un `Timer` de 1s mientras `recording`),
    `lastOutputPath` (string).
  - `start()` — dispatcher único: llama a `startScreen()`/`startRegion()`/
    `startWindow()` según `root.mode`. Es lo único que
    `RecorderWidget.qml` llama ahora.
  - `setMode(m)` — cambia la preferencia de modo; no-op mientras
    `recording` (cambiarlo a mitad de una grabación no afectaría al
    proceso ya corriendo, sería engañoso mostrarlo como si aplicara).
  - `startScreen()` / `startRegion()` / `startWindow()` / `stop()` siguen
    siendo la API interna que `start()` dispatchea — no-op si ya está
    grabando.
  - **Audio (2026-08-17, soporte de micrófono agregado)**:
    `systemAudioEnabled`/`micAudioEnabled` se combinan en `_startRecorder()`
    armando una lista de fuentes (`default_output`, `default_input`) y
    uniéndolas con `|` — sintaxis documentada en `man gpu-screen-recorder`
    para mezclar fuentes en una sola pista (`-a "default_output|default_input"`).
    Si ninguna está activa, se omite `-a` por completo (sin audio). Verificado
    en vivo con el mismo patrón de debug IPC que el resto del proyecto: cmdline
    real de `gpu-screen-recorder` inspeccionado vía `/proc/<pid>` mientras
    corría, confirmando `-a default_input` (solo mic) y
    `-a default_output|default_input` (ambas) armados correctamente; el
    archivo resultante siempre tiene una pista `opus` válida (aunque en
    silencio si nadie habló durante la prueba — mismo comportamiento ya
    documentado para el audio de sistema).
  - Los archivos de salida van a `Paths.recordingsDir`
    (`$QS_RECORDINGS_DIR` o `~/Videos/Recordings` por defecto), nombrados
    `recording-YYYYMMDD-HHMMSS.mp4`. La carpeta se crea con `mkdir -p` en
    `Component.onCompleted`.
  - **Persistencia** (`~/.local/state/quickshell/recorder.json`) —
    `mode`/`systemAudioEnabled`/`micAudioEnabled` sobreviven un restart de
    Quickshell, mismo patrón `_restored`-gate + `FileView`/`onLoaded`/
    `onLoadFailed` que `IdleManager.qml`. La carga acepta la clave vieja
    `audioEnabled` (pre-micrófono) como fallback de `systemAudioEnabled`
    para no resetear en silencio un estado ya guardado en disco.
- **`modules/bar/RecorderWidget.qml`** — ícono 󰻃 (rojo mientras graba) +
  `mm:ss` transcurrido. Click izquierdo: `Recorder.start()`/`Recorder.stop()`
  — su única función ahora. Ya no tiene click derecho ni OSD propio; elegir
  modo y audio se hace desde el dashboard (ver `RecorderSection.qml` abajo).
- **`modules/dashboard/RecorderSection.qml`** (2026-08-17, reemplaza a
  `RecorderModeOsd.qml`, que se borró) — cápsula nueva del dashboard (4ta,
  después de Weather/Battery+Performance/Music), siempre visible (no
  condicional como Music). Píldora de 3 segmentos (screen/region/window,
  mismos íconos que el OSD viejo) que llama `Recorder.setMode()` — a
  diferencia del OSD viejo, esto es una **preferencia persistida**, no una
  acción one-shot que arranca a grabar; deshabilitada (opacity 0.5,
  `MouseArea.enabled: false`) mientras graba. Dos toggles de audio
  independientes (`components/controls/Toggle.qml`) — "System audio" ligado
  a `Recorder.systemAudioEnabled`, "Microphone" ligado a
  `Recorder.micAudioEnabled` — se combinan en el pipeline, no son mutuamente
  excluyentes. Header con estado en vivo ("Idle"/"Recording mm:ss").
  `DashboardContent.qml` ganó una 4ta etapa de animación
  (`s4`/`cs1..cs5` renumerados) para el reveal/close en cascada de esta
  cápsula.

## Cómo funciona cada modo

- **`screen`** — `gpu-screen-recorder -w screen ...`, arranca directo.
- **`region`** — `slurp` interactivo (el usuario dibuja el rectángulo con
  el mouse), el output (`"X,Y WxH"`) se convierte al formato que espera
  `gpu-screen-recorder` (`-region WxH+X+Y`) y arranca con
  `-w region -region ...`.
- **`window`** — **no es un seguimiento en vivo de la ventana.** Wayland no
  tiene un equivalente portable a `-w window`/`-w focused` (eso es
  X11-only en `gpu-screen-recorder`; el único camino Wayland-nativo es
  `-w portal`, con bugs conocidos en Hyprland). En cambio: `hyprctl clients
  -j` lista las cajas delimitadoras de cada ventana mapeada, se le pasan a
  `slurp -r` (modo "elegir de una lista predefinida", vía stdin) para que
  el usuario pique una con un picker interactivo, y esa caja se graba
  exactamente como el modo `region`. Si la ventana se mueve durante la
  grabación, la captura NO la sigue — trade-off aceptado por reusar el
  camino confiable de `region` en vez de intentar portal.

## Gotchas y decisiones (importantes para no repetir)

1. **Detener la grabación requiere SIGINT específicamente, no
   `running = false`.** `gpu-screen-recorder` documenta que `Ctrl+C` es lo
   que dispara el mux/finalizado del mp4. Si se lo mata con el terminador
   por default de Quickshell (`SIGTERM`/`SIGKILL` vía
   `recorderProc.running = false`), el archivo queda corrupto/sin muxear.
   `Recorder.stop()` llama `recorderProc.signal(2)` explícitamente por
   esto — `recording` solo pasa a `false` en `onExited`, una vez que el
   proceso realmente terminó de escribir el archivo, no antes.
2. **`slurp`'s formato de output por default es `"X,Y WxH"`**
   (`"100,200 800x600"`), pero `gpu-screen-recorder` quiere
   `"WxH+X+Y"` para `-region`. `_slurpToRegionArg()` hace la conversión;
   nunca se pasa `-f` a `slurp` así que no hay sufijo de label que
   despegar.
3. **El formato de entrada de `slurp -r` está confirmado leyendo el
   man page real** (`man slurp`, no solo inferido): cada línea en stdin
   debe ser `"<x>,<y> <width>x<height> [label]"` — mismo formato que la
   salida normal de `slurp`, por eso `hyprctlClientsProc` arma las líneas
   candidatas con ese formato exacto antes de pasarlas por stdin.
4. **El modo "window" filtra ventanas con `mapped === false` o
   `hidden === true`**, y descarta cualquier cliente sin `size`/`at` o con
   ancho/alto ≤ 0 — necesario porque `hyprctl clients -j` puede listar
   ventanas en estados intermedios que no tienen geometría válida para
   ofrecer como candidata de recorte.
5. **`mode` es solo para display**, no cambia el pipeline de grabación en
   sí (los tres modos terminan llamando `_startRecorder()` con distintos
   argumentos) — está para que el widget/OSD puedan mostrar en qué modo se
   está grabando si hiciera falta más adelante.
6. **`region` no mostraba el overlay de selección — bug real, corregido
   (2026-08-17).** `man slurp`: "If the standard input is not a TTY [...]
   slurp will read a list of predefined rectangles" en vez de mostrar el
   overlay interactivo de arrastrar-para-seleccionar. El stdin de un
   `Process` de Quickshell nunca es una TTY real, así que `slurp` sin
   flags caía en silencio al modo lista-por-stdin, sin overlay y sin nada
   en stdin que leer — quedaba colgado esperando para siempre. Confirmado
   empíricamente con `hyprctl layers`: cero capas `namespace: selection`
   mientras corría sin envolver, aparecía una en cuanto se envolvía.
   Fix: `command: ["script", "-qec", "slurp", "/dev/null"]` — `script`
   (util-linux) le da un pseudo-TTY real, `-q` sin banner, `-e` propaga el
   exit code, `/dev/null` descarta la copia del typescript (el stdout real
   sigue llegando limpio al `StdioCollector`, confirmado byte a byte:
   mismo `"X,Y WxH"` de siempre, solo con `\r\n` en vez de `\n`, que
   `.trim()` ya maneja sin cambios). El modo `window` (`slurp -r`) no
   necesitó el mismo fix — `-r` fuerza el modo lista-por-stdin a propósito,
   sin importar la TTY, que es justo lo que `_pickWindowRegion` explota.

## Pendientes / no incluido

- `window` todavía no tiene verificación empírica dedicada de punta a
  punta con una selección real completada (`screen` y, tras el fix del
  gotcha #6, `region` ya están confirmados de punta a punta con una
  selección real hecha por el usuario).
- Micrófono cubre solo el dispositivo de entrada por defecto
  (`default_input`) — sin UI para elegir un sink/fuente específico
  (`device:name`, `app:name`/`app-inverse:name` de audio de aplicación)
  más allá de las dos fuentes por defecto combinables con `|`. Tampoco hay
  captura real de voz probada de punta a punta (solo el pipeline en sí,
  vía `/proc/<pid>` — nadie habló durante la prueba) — pendiente de que el
  usuario confirme un test real hablando al mic.
- Sin control de calidad/framerate/codec desde la UI — todo hardcodeado en
  `_startRecorder()` (`-c mp4`, sin flags de bitrate/fps).
- El modo `window` no sigue la ventana si se mueve o cambia de tamaño
  durante la grabación (ver limitación de Wayland arriba) — aceptado, no
  es un bug a arreglar sino el trade-off elegido.

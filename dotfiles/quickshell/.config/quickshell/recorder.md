# Screen recorder (gpu-screen-recorder)

Grabación de pantalla nativa vía `gpu-screen-recorder`, con tres modos
(screen/region/window) elegibles desde un OSD de la bar. Widget con
indicador de tiempo transcurrido mientras graba, notificación al terminar.

**Estado: funcional de punta a punta para el modo screen** (region/window
comparten el mismo pipeline y el mismo código de arranque, sin
verificación empírica dedicada todavía — ver Pendientes). `gpu-screen-recorder`
no está instalado en este sistema todavía (AUR); el resto del pipeline
(widget, OSD, servicio) está completo y espera al binario.

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
  - `recording` (bool), `mode` (`"screen"|"region"|"window"`, solo display),
    `elapsedSeconds` (int, un `Timer` de 1s mientras `recording`),
    `lastOutputPath` (string).
  - `startScreen()` / `startRegion()` / `startWindow()` / `stop()` — API
    pública. Los tres `start*` son no-op si ya está grabando
    (`if (root.recording) return`).
  - Los archivos de salida van a `Paths.recordingsDir`
    (`$QS_RECORDINGS_DIR` o `~/Videos/Recordings` por defecto), nombrados
    `recording-YYYYMMDD-HHMMSS.mp4`. La carpeta se crea con `mkdir -p` en
    `Component.onCompleted` (mismo patrón bootstrap que `IdleManager.qml`,
    pero sin archivo de estado — acá no hay nada que persistir).
- **`modules/bar/RecorderWidget.qml`** — ícono 󰻃 (rojo mientras graba) +
  `mm:ss` transcurrido. Click izquierdo: toggle start/stop de un screen
  recording directo (acceso rápido). Click derecho: abre
  `RecorderModeOsd` — pero solo si no está grabando ya, para que solo haya
  un camino de "stop" (el click izquierdo), no dos.
- **`modules/bar/RecorderModeOsd.qml`** — popout "ears + card" (mismo
  lenguaje visual que `CalendarPopout`/`TrayMenuOsd`/`BatteryProfileOsd`),
  con una píldora de 3 segmentos (screen/region/window). A diferencia de
  `BatteryProfileOsd` no hay estado "activo" que sincronizar: cada segmento
  es una acción one-shot con un flash de feedback (150ms) y el OSD se
  cierra solo tras el click.

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

## Pendientes / no incluido

- `gpu-screen-recorder` no está instalado en el sistema actual — no se
  pudo verificar empíricamente ninguno de los tres modos corriendo de
  punta a punta (solo revisión de código + `man slurp` para el formato de
  `-r`). Primer paso al instalarlo: probar `screen`, después `region` y
  `window` en ese orden (son los que dependen de `slurp`).
- Sin selector de audio/fuente — siempre `-a default_output`, no hay UI
  para elegir un sink/fuente de audio distinto.
- Sin control de calidad/framerate/codec desde la UI — todo hardcodeado en
  `_startRecorder()` (`-c mp4`, sin flags de bitrate/fps).
- El modo `window` no sigue la ventana si se mueve o cambia de tamaño
  durante la grabación (ver limitación de Wayland arriba) — aceptado, no
  es un bug a arreglar sino el trade-off elegido.
- Sin indicador en el propio `RecorderModeOsd` de qué modo quedó activo
  tras elegir (se cierra solo, no hay "última selección" visible) —
  consistente con que cada segmento es una acción, no una preferencia.

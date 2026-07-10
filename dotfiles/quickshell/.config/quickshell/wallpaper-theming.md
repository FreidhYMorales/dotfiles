# Wallpaper picker + theming-mode picker

Inspirado en caelestia-shell (referencia clonada en `/home/deadlock/Clones/shell`),
pero implementado con recursos propios: caelestia delega toda la generación de
colores/wallpaper en un binario CLI externo (`caelestia scheme/wallpaper`) que
no está instalado acá — este proyecto usa `matugen` (ya documentado como
pipeline de color) más un renderer de fondo propio en Quickshell.

## Por qué el fondo lo dibuja Quickshell, no hyprpaper

- `hyprctl hyprpaper` estaba roto en este sistema (`reload`/`listloaded`
  devolvían `invalid hyprpaper request` con el proceso corriendo).
- hyprpaper no soporta video; hubiera hecho falta sumar `mpvpaper` (no
  instalado) y hacer convivir dos herramientas con IPC propia cada una.
- El patrón Image+Video de `modules/lock/LockSurface.qml` ya estaba probado
  y funcionando — se portó casi 1:1 a `modules/background/`.
- **hyprpaper sigue corriendo** (no se desactivó su autostart) como red de
  seguridad pasiva: las dos superficies de capa "background" conviven en el
  mismo output, la de Quickshell queda arriba mientras el shell vive; si
  Quickshell se cae, la de hyprpaper (con su config estático) queda visible
  sola automáticamente. Confirmado con `hyprctl layers`.

## Arquitectura

- **`services/Wallpapers.qml`** (singleton) — escaneo de `Paths.wallpapersDir`
  (`~/Pictures/Wallpaper` por defecto, override con `QS_WALLPAPER_DIR`) vía
  `Qt.labs.folderlistmodel.FolderListModel`, imágenes y video. Estado
  `actualCurrent`/`previewPath`/`showPreview`/`current` (current = el efectivo,
  al que se bindea el fondo real). `preview()/stopPreview()/commit()`.
  Persiste en `~/.local/state/quickshell/wallpaper.txt`.
- **`modules/background/`** — `Background.qml` (`Variants` por monitor,
  `WlrLayershell` en layer `Background`) + `BackgroundSurface.qml` (Image+Video,
  portado de `LockSurface.qml`, bindeado a `Wallpapers.current`).
- **`services/Colours.qml`** — extendido con:
  - Catálogo `modes`: los 9 tipos reales de matugen (`--type scheme-*`):
    tonal-spot ("Default"), monochrome ("Mono"), vibrant, expressive,
    fidelity, content, neutral, rainbow, fruit-salad.
  - `currentMode`/`isLight`/`dynamic` (auto-regenerar colores al cambiar de
    wallpaper), persistidos en `~/.local/state/quickshell/theme.json`.
  - `commit(modeId, isLight)` — persiste y dispara matugen contra el
    wallpaper actual.
  - `regenerateFrom(path, isVideo)` — invocación real de matugen (aplica a
    `colors.json`, el que el shell usa de verdad). Para video, extrae un
    frame primero con `ffmpegthumbnailer`.
  - `generatePreviews(path, isVideo)` — batch de 9 llamadas a matugen
    **`--dry-run --json hex`** (nunca toca `colors.json` real) contra el
    wallpaper actual, una por una (cola secuencial, no paralelo), cacheadas
    en `previewCache` para que el picker de temas muestre swatches reales.
    Se dispara al entrar a `>theme ` y también al confirmar un wallpaper
    nuevo (para no quedar con previews del wallpaper viejo).
- **`~/.config/matugen/config.toml`** + **`colors.json.template`** — template
  Jinja propio (no el dump nativo de matugen) que emite exactamente el shape
  que `Colours.qml.parse()` espera (`{"scheme": "...", "colors": {"primary":
  {"hex": "..."}, ...}}`, 35 roles Material 3).

## Convención de comandos del launcher (estilo caelestia)

- Escribir `>` solo (o `>algo`) lista los comandos disponibles
  (`LauncherContent.qml`'s `commands`: wallpaper, theme) con ícono + nombre +
  descripción (`CommandItem.qml`).
- Elegir un comando (click/Enter) completa `>wallpaper ` / `>theme `
  (con el espacio final) y sigue tipeando ahí — no cierra el launcher.
- `>wallpaper <query>` → carousel horizontal infinito (`PathView`, no
  `ListView` — `WallpaperCard.qml` como delegate). Izquierda/derecha (o
  arriba/abajo) navegan sin límite, el modelo "envuelve" solo en ambas
  direcciones (comportamiento nativo de `PathView.currentIndex`, no hubo que
  programar el wraparound). El centrado usa `highlightRangeMode:
  StrictlyEnforceRange` + `preferredHighlightBegin/End: 0.5`; el path define
  `itemScale`/`itemOpacity` para que la tarjeta centrada se vea más grande y
  opaca que las de los costados (coverflow liviano, sin path curvo). Preview
  en vivo del fondo real mientras navegás, revierte con Escape/al cerrar sin
  confirmar — igual que antes. El recorte redondeado de la miniatura usa
  máscara (`MultiEffect`), no `clip: true` — ese solo recorta al rectángulo
  bounding box, ignora `radius` por completo; el ítem de contenido crudo
  (esquinas cuadradas) debe quedar `visible: false`, si no se asoma detrás
  de la versión enmascarada.
- `>theme <query>` → `ThemeModeItem.qml` (swatch circular partido
  primario/secundario con máscara circular — mismo truco que `LockAvatar.qml`
  — borde/divisor fijo negro en claro / blanco en oscuro, nunca un color de
  matugen, para que el corte se vea siempre). Tab o el botón de la barra de
  búsqueda alternan claro/oscuro y aplican al toque sobre el modo activo
  (no hace falta re-confirmar un modo para que tome efecto).

## Gotchas encontrados (importantes para no repetir)

1. **`FileView.watchChanges` NO recarga el contenido solo.** Solo emite
   `onFileChanged` cuando el archivo cambia — `onTextChanged`/`text()` NO se
   actualizan automáticamente. Hace falta `onFileChanged: view.reload()`
   explícito. Confirmado con test aislado: un `echo > file` sobre un archivo
   ya cargado dispara `fileChanged` pero nunca `textChanged` sin ese
   `reload()`. Este bug hacía que cambiar de wallpaper/tema regenerara
   `colors.json` correctamente pero el shell nunca lo recargara en vivo
   (solo se veía el color nuevo reiniciando el proceso). Fix en
   `services/Colours.qml`'s `colorsFile` FileView.
2. **matugen necesita `--prefer <criterio>`** (ej. `saturation`) cuando la
   imagen tiene múltiples colores candidatos — sin eso, pide input
   interactivo y cuelga cualquier invocación no interactiva (`Process` de
   Quickshell, scripts, etc).
3. **matugen no lee video directamente** — para wallpapers de video hay que
   extraer un frame primero (`ffmpegthumbnailer -i <video> -o <png> -s 512`)
   y pasarle ESE frame a matugen. Aplica tanto al commit real
   (`regenerateFrom`, vía `Colours._extractFrame`/`extractFrameProc`) como a
   los previews (`generatePreviews`, vía `Colours._extractFramePreview`/
   `previewExtractFrameProc`) — **deliberadamente en procesos y archivos de
   salida separados** (ver gotcha 8, antes compartían uno solo y eso rompía
   el commit real para wallpapers de video).
4. **El dump nativo de matugen (`-j/--json hex`) usa `.color`** anidado bajo
   `dark`/`light`/`default` (`--mode` determina cuál llena `default`) — **no**
   es el mismo shape que un TEMPLATE Jinja (`{{colors.x.default.hex}}`, con
   `.hex`). No confundir ambos formatos al parsear.
5. **Ninguna capa de layer-shell entra en conflicto por estar duplicada** —
   Hyprland apila varias superficies en el mismo layer por orden de mapeo
   (la última mapeada queda arriba), así que hyprpaper + el fondo propio de
   Quickshell conviven sin banderas especiales.
6. **`qs ipc` sin `-p` asume la config `"default"`** (ver `lockscreen.md`)
   — recordatorio también relevante acá, cualquier IPC de debug necesita el
   path explícito.
7. **Acumular stdout línea por línea con `SplitParser` + leerlo en
   `onRunningChanged` puede leer el buffer incompleto** para salidas grandes
   (el dump `--json hex` de matugen son ~18KB / cientos de líneas) — hay una
   carrera entre el evento "proceso terminó" y que terminen de llegar los
   últimos chunks de stdout. Confirmado: **todos** los 9 previews de tema
   fallaban con `JSON.parse` al generarse contra un wallpaper de video (el
   frame extraído hacía la corrida de matugen más lenta/grande, exponiendo la
   carrera). Fix: `Quickshell.Io.StdioCollector` (`stdout: StdioCollector {
   onStreamFinished: ... } }`) en vez de `SplitParser` + buffer manual —
   `streamFinished` solo dispara cuando el stream completo ya se capturó.
   Ver `Colours.qml`'s `previewProc`.
8. **Un solo `Process` reusado para dos flujos que se llaman casi al mismo
   tiempo pierde el segundo callback.** `Wallpapers.commit(path)` llama a
   `Colours.regenerateFrom()` (si `dynamic` está activo) Y a
   `Colours.generatePreviews()` en la misma función, uno después del otro,
   sin esperar — si ambos comparten el mismo `Process` de extracción de
   frame (`extractFrameProc.onDone = ...; extractFrameProc.running = true`),
   el segundo `running = true` es un no-op mientras el primero sigue
   corriendo, y el segundo `onDone` pisa al primero — el commit real
   (colores aplicados) nunca corría para wallpapers de video, solo el
   preview. Fix: procesos de extracción completamente separados para cada
   flujo (`extractFrameProc` vs `previewExtractFrameProc`, con archivos de
   salida distintos también).

9. **Warning benigno, no confirmado del todo:** al navegar rápido por el
   carousel de wallpapers alternando video/imagen, a veces aparece en el log
   `[image2 @ ...] Could not find codec parameters...` + `Input #0, image2,
   from '<algo>.jpg'` — FFmpeg intentando abrir una IMAGEN como si fuera
   video. Sospecha (no verificada al 100%): un frame de transición donde el
   `Video` de `BackgroundSurface.qml` alcanza a recibir la ruta nueva antes
   de que `isVideo` (depende de una función, no de una property simple)
   termine de recalcularse. Usuario confirmó que no hay ningún glitch visual
   asociado — se deja como nota, no como bug a arreglar, salvo que aparezca
   un síntoma visual real.
10. **`PathView.pathItemCount` controla la densidad visual, no solo cuántos
    ítems existen** — con el mismo ancho de `Path`, menos ítems (`pathItemCount`
    bajo) reparten el mismo recorrido entre menos tarjetas, así que se ven
    más separadas entre sí. El mini-carrusel del panel `>screensaver` tenía
    `pathItemCount: 3` contra el `5` del carrusel principal — mismo ancho,
    pero notablemente más espaciado. Igualado a `5` para que ambos se vean
    igual de compactos.
11. **`PathView` no apila el ítem central/activo por encima de sus vecinos
    por defecto** — el borde derecho de la tarjeta seleccionada (escalada a
    `1.0`, más grande) podía quedar por DEBAJO del borde izquierdo de la
    tarjeta vecina (escalada a `0.72`), ya que el z-order por defecto sigue
    el orden del modelo, no el scale/estado actual. Fix: `z:
    PathView.isCurrentItem ? 1 : 0` en el delegate — aplicado en los dos
    carruseles (`>wallpaper` y el mini-picker de `>screensaver`).
12. **El "primer evento de posición tras mapear una superficie no es
    movimiento real" (mismo gotcha ya documentado para `LockIdle.qml` en
    `idle-screensaver.md` #7) también afecta al hover del carrusel de
    wallpapers** — si Hyprland tiene el cursor oculto por config y el mouse
    queda físicamente quieto sobre donde aparece el carrusel al abrir el
    launcher, el `HoverHandler` de la tarjeta bajo esa posición reporta
    "hover" apenas se mapea la superficie (evento sintético de Wayland con
    la posición YA existente del cursor, no un movimiento real), disparando
    `currentIndex = index` sin que el usuario haya movido nada — el
    carrusel "empieza a scrollear solo". Fix: mismo patrón baseline +
    umbral de 4px que `LockIdle.qml` ya usaba, pero vía un `MouseArea`
    invisible (`acceptedButtons: Qt.NoButton`, nunca compite con los clicks
    de las tarjetas) que solo habilita `onHovered → currentIndex` una vez
    que se detecta movimiento real. Rearmado tanto al abrir el launcher
    como al cambiar de modo/al mostrarse el mini-picker — aplicado en
    ambos carruseles.

## Picker del `>screensaver` — replica visual del carrusel principal (agregado después)

El mini-picker de fondo distinto dentro de `ScreensaverForm.qml` ahora
comparte densidad (`pathItemCount: 5`), z-order de la tarjeta activa, y el
guard de movimiento real con el carrusel principal de `>wallpaper` — ver
gotchas #10, #11 y #12 arriba. Sigue siendo más chico en tamaño de tarjeta
(100×110 vs 130×170) porque vive en un espacio más acotado dentro del panel
de configuración, pero se ve proporcionalmente igual de compacto.

## Miniaturas de video en el carrusel (agregado después)

Antes, cada tarjeta de video en el carrusel de `>wallpaper`
(`modules/launcher/WallpaperCard.qml`) solo mostraba un ícono de cámara
(`󰃽`) sobre fondo plano — sin ninguna vista previa real del contenido.
Ahora `services/Wallpapers.qml` mantiene una caché propia de miniaturas
(`videoFrameCache`, `videoPath → ruta del PNG extraído`), reusando
`ffmpegthumbnailer` igual que `Colours.qml` ya hace para matugen, pero **con
un archivo de salida por video** (`${Paths.cache}/quickshell-wallpaper-thumbs/<nombre>.png`,
no un único path compartido) y una cola secuencial (`_frameQueue`/
`_processFrameQueue()`) para no lanzar varias extracciones en paralelo si el
carousel tiene varios videos sin miniatura todavía. `WallpaperCard.qml` pide
su frame en `Component.onCompleted`/`onWallPathChanged` y muestra la imagen
extraída en cuanto está lista; el ícono de cámara queda solo como estado de
"todavía no" (o si `ffmpegthumbnailer` no está instalado — reusa
`Colours.ffmpegthumbnailerAvailable`, el mismo chequeo ya existente, no uno
nuevo). Esta caché es independiente de la de `Colours.qml` (paths de salida
distintos) — no compite ni se pisa con la extracción que usa matugen para
recolorear.

## Post-hook de matugen (agregado 2026-07-07)

Cuando `matugenProc` termina con exitCode 0, `Colours.qml` dispara `postHookProc` que corre `~/.config/matugen/post-hook.sh`. Ese script:
- Recarga Kitty via socket (`kitten @ set-colors`)
- Recarga btop via `SIGUSR2`
- Recarga Hyprland via `hyprctl reload` (para que tome `deadlock/colors.lua` nuevo)
- Copia `zen-matugen.css` al perfil activo de Zen Browser
- Sincroniza hyprpaper (reescribe conf + reinicia proceso)
- Sincroniza SDDM silent theme (wallpaper + colores matugen via helper sudo)

**Gotcha**: `run_hook` en `config.toml` de matugen 4.1.0 no funciona — por eso el hook se dispara desde QML y no desde matugen.

## Sync con hyprpaper y SDDM (agregado 2026-07-07)

Además del theming de colores, el post-hook sincroniza el wallpaper activo con dos destinos que no leen el background de Quickshell directamente:

### hyprpaper

hyprpaper corre como fallback pasivo (queda tapado por `modules/background/`, pero toma el
control si Quickshell se cae). El post-hook:
1. Lee `~/.local/state/quickshell/wallpaper.txt` (path absoluto del wallpaper actual)
2. Si es video (mp4, mkv, webm, gif, mov, avi): extrae el primer frame con
   `ffmpeg -ss 0.0 -i <video> -vframes 1 -q:v 2 ~/.local/state/quickshell/hyprpaper-frame.jpg`
   hyprpaper no soporta video — se usa el frame estático
3. Reescribe `~/.config/hypr/hyprpaper.conf` con el path efectivo
4. **Sin reiniciar hyprpaper** — solo actualiza el config para el próximo arranque (ver gotcha abajo)

### SDDM silent theme

El tema SDDM siempre lee `configs/custom.conf` (`metadata.desktop:ConfigFile`).
El background se antepone con `"backgrounds/"` en `Main.qml` — no acepta paths absolutos. Por eso:
1. El post-hook genera `custom.conf` completo en `/tmp/sddm-custom.conf` con colores
   de matugen (`primary`/`on_primary` leídos de `colors.json` con python3 — ver gotcha)
2. Llama a `sudo /usr/local/bin/sddm-theme-sync` (NOPASSWD, `/etc/sudoers.d/sddm-theme-sync`):
   - Borra `backgrounds/qs-current.*` anterior
   - Copia wallpaper a `backgrounds/qs-current.<ext>`
   - Sobreescribe `configs/custom.conf`

**Colores tematizados en SDDM**: fecha del reloj → `primary`; borde de avatar → `primary`;
borde del input de contraseña → `primary`; botón de login → filled M3 (`primary` bg + `on_primary` icon);
virtual keyboard primary → `primary`; active-content en popups → `primary`.
Texto del reloj y username siempre blanco (legibilidad sobre wallpaper oscuro).

**Gotcha — no reiniciar hyprpaper mientras Quickshell corre**: layer-shell apila superficies en la
capa `background` por orden de mapeo (última mapeada = encima). Al arrancar el sistema,
hyprpaper se mapea primero → Quickshell lo mapea después → Quickshell queda encima ✅.
Si se reinicia hyprpaper con Quickshell ya corriendo, hyprpaper se mapea después → queda
encima y tapa el fondo de Quickshell (incluyendo wallpapers de video). El post-hook solo
actualiza el config sin reiniciar — hyprpaper leerá el nuevo wallpaper en el próximo boot.

**Gotcha — usar python3 en lugar de jq**: `jq` no está instalado en este sistema.
El post-hook usa `python3 -c "import json; d=json.load(open('$F')); print(d['colors']['primary']['hex'])"`.
Es la dependencia más segura (python3 es parte de Arch base). Si `jq` se instala después
(`bootstrap.sh` lo incluye en CLI tools), se puede simplificar, pero python3 funciona igual.

---

## Pendientes / no incluido

- Multi-monitor: mismo wallpaper en todos los outputs (el usuario tiene un
  solo monitor hoy). Selección por monitor no implementada.
- El toggle claro/oscuro no re-genera los 9 previews del picker de temas al
  cambiarlo (solo afecta el próximo commit real) — los swatches muestran la
  paleta generada con el `isLight` que estaba activo cuando se abrió `>theme`.

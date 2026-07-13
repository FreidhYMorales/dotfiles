# Contexto — Disco Externo / Configuraciones

Este directorio vive en un disco externo. Se usa en cada reinstalación de Arch Linux
como fuente de verdad para dotfiles, referencias y memoria de proyecto.

**Usuario:** deadlock — yannelmorales51@gmail.com  
**Stack:** Arch Linux · Hyprland · Quickshell (QML/Qt6) · Neovim · Yazi · zsh  
**Máquina destino:** Lenovo ThinkPad X1 Carbon Gen 13 — Intel Core Ultra 200V (Lunar Lake), Intel Arc (xe driver), sin GPU dedicada. Usar `--no-gpu` en bootstrap.
**GPU anterior:** NVIDIA (Dell) — los fixes NVIDIA siguen en backup/references/caelestia/caelestia-patterns-reference.md pero ya no aplican a la máquina principal.

---

## Estructura

```
Configuraciones/
├── CLAUDE.md          ← este archivo
├── install.sh         ← entry point curl-able (detecta repo / clona si falta)
├── .gitignore         ← excluye backups/, secrets, runtime SDDM, fg.yazi, etc.
├── dotfiles/          ← paquetes Stow — deploy.sh los symlinks a $HOME
│   ├── bootstrap.sh   ← instalación completa (25 pasos), llama deploy.sh al final
│   ├── deploy.sh      ← ./deploy.sh [pkg] [--dry-run]
│   └── nvim/ yazi/ zsh/ kitty/ hypr/ quickshell/ git/ scripts/
│       fonts/ vesktop/ betterdiscord/ mimeapps/ termfilechooser/ xdg-portal/
│       matugen/ ...
├── system/            ← configs sudo-level (no van a $HOME, no son Stow)
│   └── sddm/
│       ├── themes/silent/          ← tema SDDM completo (copiado a /usr/share/sddm/themes/)
│       └── sddm.conf.d/the_hyde_project.conf
└── backup/            ← backups, referencias, configs anteriores
    ├── references/    ← documentación de referencia (LEER PRIMERO)
    ├── backups/       ← ⚠️ SENSIBLE — gnupg, ssh, gh (gitignoreado)
    ├── quickshell/    ← symlink → ../dotfiles/quickshell/.config/quickshell
    ├── archive/       ← configs obsoletas (hypr pre-Omarchy, etc.)
    └── ...configs/    ← nvim, yazi, zsh, kitty, etc.
```

---

## Qué leer primero en una sesión nueva

1. `backup/references/README.md` — índice de toda la documentación
2. `backup/references/packages-reference.md` — lista completa de paquetes + orden de instalación
3. `backup/references/quickshell-vision.md` — visión del Quickshell propio
4. `backup/references/deploy-strategy.md` — cómo deployar los dotfiles con Stow
5. `backup/references/matugen-pipeline-reference.md` — pipeline de colores
6. `backup/references/caelestia/` — arquitectura y patterns de Caelestia (referencia QML)
7. `backup/references/end-4/` — arquitectura y patterns de ii/illogical-impulse (referencia QML)

---

## Estado actual del proyecto

### Dotfiles / Bootstrap
- **Git repo inicializado** en la raíz de `Configuraciones/` — 4 commits (rama `main`)
- **`install.sh`** — entry point curl-able. Detecta si el repo ya existe en disco o clona desde `$REPO_URL`. Luego llama a `bootstrap.sh`. Flags: `--no-gpu`, `--dir=<path>`
- **`dotfiles/bootstrap.sh`** — 33 pasos, cubre todo el sistema desde cero:
  - Flags: `--no-gpu` (salta NVIDIA — usar en ThinkPad), `--no-grub` (salta GRUB theme), `--grub-res=WxH`
  - Instala: Hyprland, GPU, shell+OMZ, CLI tools, Neovim+runtimes, Yazi, Audio+sof-firmware, screenshots, clipboard, notificaciones, OCR, screen recording, theming (matugen+spicetify), **apps (vesktop+zen-browser-bin+chromium+mpv)**, Quickshell+qt5/qt6-wayland, system utils (power-profiles-daemon+ntfs-3g), fonts, SDDM silent theme, termfilechooser, iwd+impala+bluez+bluetui, lenguajes (lua, java, c++, python-extras, pnpm), GRUB Star Wars
  - Step 31 — Boot optimization: mask `systemd-networkd-wait-online` (~2 min de boot), cups socket activation, Intel xe Early KMS (cuando `--no-gpu`)
  - GRUB timeout = 3s, kernel params `quiet loglevel=3 nowatchdog`
  - Termina con `deploy.sh`, `xdg-user-dirs-update`, `fc-cache`, `luarocks magick`, `ya pack -i`, MPD, sddm-theme-sync helper
- **Paquetes Stow activos** (todos en `PENDING=()`): nvim, yazi, zsh, kitty, hypr, quickshell, git, scripts, matugen, fonts, vesktop, betterdiscord, mimeapps, termfilechooser, xdg-portal + otros
- `secrets.zsh` vive en `dotfiles/zsh/.config/zsh/secrets.zsh` (gitignoreado) — restaurar GEMINI_API_KEY manualmente
- `git config --global safe.directory` ya está en `.gitconfig` para rutas del disco externo; también incluye credential helper de gh CLI
- **`backup/quickshell/`** es un symlink → `../dotfiles/quickshell/.config/quickshell` — un solo source of truth, sin sync manual
- **`system/sddm/`** — tema silent completo + conf. Bootstrap lo copia a `/usr/share/sddm/themes/` y `/etc/sddm.conf.d/`. Runtime files (custom.conf, qs-current.*) gitignoreados
- `sddm-theme-sync` helper instalado en `/usr/local/bin/` con sudoers entry — llamado desde el post-hook de matugen para actualizar colores SDDM dinámicamente

### Quickshell propio
- Visión definida en `backup/references/quickshell-vision.md`
- **EN DESARROLLO ACTIVO** — shell funcional con bar, launcher, dashboard
- Proyecto en `backup/quickshell/` — estructura:
  - `modules/lock/` — lockscreen completo, port visual del theme SDDM "silent" (ver `lockscreen.md` en el proyecto, fases 0-6 terminadas)
  - `modules/bar/`, `dashboard/`, `launcher/`, `notifications/` — en progreso
  - `components/` — StyledText, MaterialIcon, AnimLoader, StateLayer, Logo + submodules (controls, containers, effects, images, widgets, misc)
  - `services/` — Audio, Battery, Colours (con .palette/.tPalette), Time, Weather, Notifs, Players, Hypr, SysInfo...
  - `utils/` — Paths, SysInfo (string props), Icons, CUtils
- **Próximo paso: implementar plugins propios** — ver `backup/references/quickshell-pending-plugins.md`
  - M3Shapes (MaterialShape en C++/Rust) — pendiente para el dashboard/bar visual
- Pipeline de colores: matugen → 6 templates → FileView en Quickshell + apps externas (ver `wallpaper-theming.md` y `matugen-pipeline-reference.md`)
- **Theming multi-app activo**: Kitty (live via socket), btop (SIGUSR2), Hyprland borders/shadow (hyprctl reload), Zen Browser (CSS al perfil), Zellij (nueva sesión), **hyprpaper** (reescribe conf + reinicia proceso; si el wallpaper es video extrae primer frame con ffmpeg), **SDDM** (genera `configs/custom.conf` con colores matugen + copia wallpaper a `backgrounds/qs-current.<ext>` via helper privilegiado `/usr/local/bin/sddm-theme-sync`), **GTK + Electron + Zen** (`gsettings set org.gnome.desktop.interface color-scheme "prefer-dark/light"` — propagado en el post-hook pasando el argumento `light|dark` desde `Colours.qml`). Post-hook en `~/.config/matugen/post-hook.sh`, llamado desde `Colours.qml` `matugenProc.onExited` (no desde matugen — `run_hook` no funciona en 4.1.0). Usa `python3` para leer `colors.json` (no `jq` — no está instalado en este sistema)
- Font: Iosevka Term Nerd Font (`ttf-iosevkaterm-nerd`)
- Referencias completadas:
  - Caelestia → `backup/references/caelestia/` (3 archivos: arquitectura + patterns QML + config personal)
  - end-4/ii → `backup/references/end-4/` (4 archivos: arquitectura + patterns QML + Hyprland + tools)
  - monasm-dots → `/home/deadlock/dotfiles/monasm-dots` (instalado — referencia visual/layout ✅)

#### Estado actual de la barra (`modules/bar/`)
- Todos los widgets usan `radius: height / 2` — círculo perfecto (26×26px) o pill para los que tienen texto extra
- `LauncherButton`: ícono Arch Linux `󰣇`, abre el launcher con `Visibilities.toggle("launcher")`
- `BgAppsWidget`: ya tenía `radius: height / 2` ✅
- No tiene sombra QML (se intentó con `MultiEffect` pero no quedó bien visualmente)
- **Fondos sólidos** (sin glassmorphism) en bar/launcher/OSD/dashboard/notificaciones — `Qt.alpha()` sacado de los fondos de panel/card/pill en 14 archivos (detalle: memoria `bar_theming_and_tray`, engram `quickshell/solid-backgrounds-migration`). Quedó a propósito sin tocar: hover/press de `StateLayer`, líneas divisorias, tracks de progreso/volumen, 2 toggles.
- **Las 6 píldoras de la barra** (workspaces, derecha, CPU, RAM, BgApps, reloj) + la del power del perfil del dashboard comparten el mismo criterio visual: relleno `m3surfaceContainerHigh` + borde 1px con `Colours.mid(bg, fill)` (nuevo helper en `Colours.qml`, punto medio RGB) — el fondo de la barra es casi negro, así que la definición viene del borde, no de contraste de relleno.
- **Reloj muestra solo `hh:mm`** (usa `Time.time24`, no `Time.timeFull`) — los segundos fueron removidos.
- **`BgAppsWidget` ahora lee `Quickshell.Services.SystemTray`** (antes leía `Hyprland.toplevels`, que no puede ver apps sin ventana como Vesktop minimizado a bandeja) — click derecho en un ícono abre `TrayMenuOsd.qml` (mismo estilo orejas+tarjeta que los demás OSD, usando `QsMenuOpener`/`QsMenuEntry`).
- **Click en los círculos de workspace** ahora sí cambia de workspace — usaba `Hyprland.dispatch()` (roto en este Hyprland, ver gotcha de Lua abajo), corregido a `hyprctl dispatch "hl.dsp.focus({workspace=N})"`.
- **Widget de grabación de pantalla** (`RecorderWidget.qml` + `services/Recorder.qml` + `RecorderModeOsd.qml`) — envuelve `gpu-screen-recorder` (AUR, **no instalado todavía**, correr `yay -S gpu-screen-recorder`). Auto-detecta GPU por equipo (NVENC/VAAPI), así funciona igual en el desktop NVIDIA y en la Thinkpad Intel. Click izquierdo: inicia/detiene grabación de pantalla completa. Click derecho (solo si no está grabando): abre el picker de 3 modos (pantalla/región/ventana). "Modo ventana" es un recorte estático al bounding box de la ventana elegida (vía `hyprctl clients -j` + `slurp -r`), no sigue a la ventana si se mueve — en Wayland/Hyprland no hay captura de ventana en vivo confiable (`-w window` es solo X11, `-w portal` tiene bug documentado en Hyprland). Detalle completo: memoria `screen_recorder_widget.md`, engram `quickshell/screen-recorder`.

#### Estado actual del launcher (`modules/launcher/`)
- Anclado en la parte inferior (`bottom: true`), crece hacia arriba
- Animación: precircle (arc) → circle (logo Arch) → bar → open
- **Navegación con teclado**: Up/Down cambian `selectedIndex`, auto-scroll con `positionViewAtIndex(selectedIndex, ListView.Contain)`
- **Mouse hover**: también actualiza `selectedIndex` (signal `hovered()` en `AppItem`)
- **Selección visual en `AppItem`**: barra lateral de 3px (`m3primary`) + fondo `m3primaryContainer` translúcido + nombre y fondo de ícono cambian a `m3primary`
- Enter lanza `filtered[selectedIndex]` (no siempre el primero)
- **Ícono de `AppItem` ahora es un cuadrado con bordes redondos** (`radius: 12`, antes círculo perfecto `radius: height/2`)
- **Fix**: la letra de fallback (apps sin ícono real) quedaba invisible al seleccionar la app — su color pasaba a `m3primary`, igual que el fondo del ícono ya seleccionado (bug de copiado). Corregido a `m3onPrimary` (el rol pensado para contrastar sobre `m3primary`) en `AppItem.qml`, y se encontró el mismo bug exacto en `CommandItem.qml` (lista de comandos `>`) y `ThemeModeItem.qml` (`>theme`) — corregido en los 3 archivos
- **`>webapp` command**: instala un web app launcher desde URL+nombre. Descarga favicon via Google Favicons API, genera `.desktop` con `Exec=webapp-launch <url>`. `webapp-launch` detecta el browser default: si es Chromium-based usa ese, si no (Zen es Firefox-based) cae a `chromium` con `--app=<url>`. Scripts en `dotfiles/scripts/.local/bin/`. Chromium es requerido para esto (instalado en bootstrap step 16).

#### OSDs — click abre/cierra + hover mantiene abierto (volumen, batería, calendario, dashboard)
- Patrón unificado en 4 popups: `Osd.qml` (volumen), `BatteryProfileOsd.qml`, `CalendarPopout.qml`, `DashboardContent.qml`
- Click en el widget de la barra abre/cierra (`Visibilities.toggle(...)`, toggle explícito)
- `HoverHandler` en la tarjeta/panel: hover pausa el auto-cierre; al salir del hover arranca un `Timer` de 1000ms que cierra
- El volumen ya no tiene auto-cierre "por defecto" al abrir (se sacó el `restart()` automático que corría sin importar el hover) — ahora solo cierra por click en el botón, por hover-leave (1s), o Escape
- **Pendiente / bug sin resolver**: el segundo click en el widget de volumen (para cerrar el OSD) no funciona, reproducido incluso tras reiniciar la PC. Escape sí cierra correctamente (confirma que la lógica de cierre en `Osd.qml` está bien) — el problema está en que el click del widget no llega a togglear `Visibilities.volume` la segunda vez. Revisado a fondo sin encontrar la causa estáticamente (un solo call site de `toggle("volume")`, sin gating raro, sin desync entre el `MouseArea` y el ancho animado del ícono+porcentaje). Próximo paso: correr `qs` en foreground o revisar su log en vivo mientras se reproduce, para cazar un warning de QML en el momento exacto del click.

#### Dashboard — botones de power
- **`ProfileSection.qml`** (pill de power en el widget de perfil) y **`SessionSection.qml`** (fila de 5 acciones al pie del dashboard): los íconos usan el patrón de `PowerMenuButton` — solo el ícono `Text`, sin `Rectangle` de fondo. Hover: color `m3primary` + `scale: 1.35` con `NumberAnimation 180ms OutCubic`. Sin fondo ni highlight de área.

#### Bugs corregidos
- **Network.qml flicker**: el Timer reseteaba `connected/signal/ssid` antes de correr el proceso → ícono flickeaba cada 3s. Fix: bufferizar en props privadas del `Process` (`_connected`, `_signal`, `_ssid`) y aplicar todo junto en `onRunningChanged` cuando el proceso termina.
- **`SysInfo.qml` detectaba GPU NVIDIA como falso positivo**: `hasGpu` se chequeaba con `command -v nvidia-smi` (solo confirma que el binario existe). En una máquina sin NVIDIA (Intel HD 520 + AMD discreta, confirmado con `lspci`) que tiene `nvidia-smi` instalado como leftover de un `bootstrap.sh` viejo (que asumía NVIDIA siempre, ver commit "auto-detect GPU vendor"), el binario existe pero falla con exit 9 al correr — el círculo de GPU del dashboard quedaba visible mostrando 0% fijo en vez de ocultarse. Fix: `nvidia-smi -L` (consulta al driver de verdad) en vez de `command -v`.

#### Estado actual del lockscreen (`modules/lock/`)
- Port visual completo del theme SDDM "silent" — fases 0-6 terminadas (detalle en `lockscreen.md` del proyecto)
- Escala independiente del scale/resolución de Hyprland (ancla a 1920×1080 físicos)
- Botones de Lock/Logout del dashboard corregidos (`qs ipc -p <path>`, `hyprctl dispatch 'hl.dsp.exit()'` — este Hyprland enruta `dispatch`/`keyword` por un puente Lua)
- **Tema activo por defecto: `custom`** (antes `default`), con fondo = wallpaper real (sentinel `background = wallpaper`, resuelve directo a `Wallpapers.current` — **no** a `IdleManager.effectiveScreensaverSource`, ver fix de 2026-07-03 abajo) y ~12 colores de acento atados a la paleta matugen (sentinel `color = m3primary` etc., función `LockConfig.colorValue()`)
- **Fix (2026-07-03)**: el sentinel `background = wallpaper` había empezado a seguir el fondo del salvapantallas en vez del wallpaper real, una vez que el panel `>screensaver` permitió que el salvapantallas usara una imagen distinta — las dos fuentes coincidían por casualidad antes de que existiera esa opción. Corregido en `LockSurface.qml` (detalle: `idle-screensaver.md` gotcha #15)
- **Estilo custom del teclado virtual — portado** (`modules/lock/assets/vkeyboard-styles/.../LockKeyboard/style.qml`) — requiere `export QML_IMPORT_PATH=".../modules/lock/assets/vkeyboard-styles"` antes de lanzar `qs` (no hay launcher fijo todavía para persistir esto)
- **Pendientes reales** (ver sección homónima en `lockscreen.md`):
  1. `LockConfig.lockScreenDisplay` (saltar pantalla ociosa) parseado pero no consumido
  2. `LockIconButton.qml` tiene un `Component.onCompleted` con el mismo patrón de riesgo de carrera ya arreglado en otros archivos del lock — sin síntoma reportado, sin tocar
  - (El bug de `services/Colours.qml:151` — falta `()` en `colorsFile.text` — ya se arregló como parte del feature de wallpaper/theming, ver `wallpaper-theming.md`)

#### Wallpaper picker + theming-mode picker (launcher, `>wallpaper` / `>theme`)
- Detalle completo en `wallpaper-theming.md` del proyecto — feature nueva, funcional de punta a punta
- Fondo de escritorio renderizado por el propio Quickshell (`modules/background/`), no hyprpaper — hyprpaper sigue corriendo como fallback pasivo (misma capa, queda tapado)
- `services/Wallpapers.qml` (scan + preview en vivo + persistencia) + `services/Colours.qml` extendido (9 modos matugen + claro/oscuro + preview de swatches vía `--dry-run`)
- Launcher: `>` lista comandos (ícono+nombre+descripción, estilo caelestia), `>wallpaper `/`>theme ` (con espacio) entran al picker específico
- **Gotcha importante para recordar**: `FileView.watchChanges` NO recarga contenido solo — solo emite `onFileChanged`, hace falta `reload()` explícito ahí. Ver detalle en `wallpaper-theming.md`
- **Miniaturas de video en el carrusel**: las tarjetas de video ahora muestran un frame real (extraído con `ffmpegthumbnailer`, reusando el mismo binario que ya usa `Colours.qml` para matugen) en vez de solo un ícono de cámara — caché propia por archivo en `Wallpapers.videoFrameCache` con una cola secuencial, ver `wallpaper-theming.md`
- **Picker del `>screensaver` igualado visualmente al de `>wallpaper`**: mismo `pathItemCount: 5` (antes 3, se veían más separadas), mismo `z: PathView.isCurrentItem ? 1 : 0` (la tarjeta activa quedaba tapada por la vecina), y mismo guard de "movimiento real del mouse" en los dos carruseles — con el cursor oculto por config de Hyprland, el hover sintético al abrir el launcher hacía que el carrusel "empezara a scrollear solo" apenas se abría. Ver `wallpaper-theming.md` gotchas #10/#11/#12

#### Salvapantallas + auto-bloqueo + auto-suspensión + modo caffeine
- Detalle completo en `idle-screensaver.md` del proyecto — funcional de punta a punta, verificado empíricamente (incluida una suspensión real)
- Nativo con `Quickshell.Wayland` (`IdleMonitor`/`IdleInhibitor`, protocolos `ext-idle-notify-v1`/`ext-idle-inhibit-v1`), no hypridle (binario no instalado, config huérfana)
- `services/IdleManager.qml` — timeouts persistidos (3/5/15 min default), `caffeineMode` solo de sesión
- **Decisión clave**: el bloqueo real se dispara ya al llegar al umbral del salvapantallas (no en un umbral separado) — `ext-session-lock-v1` tapa cualquier otra superficie sin excepción una vez bloqueado, así que el salvapantallas se renderiza DENTRO de `modules/lock/LockSurface.qml` (modo `useScreensaverBg`) para que el video/imagen nunca se reinicie. Solo pide contraseña si pasa un tiempo de gracia extra configurable; si no, libera sin pedirla
- Botón de caffeine (taza llena/vacía) en `modules/bar/BatteryProfileOsd.qml`, al lado del selector de perfil
- **Gotcha crítico para recordar**: `IdleMonitor.timeout` está en SEGUNDOS, no milisegundos — multiplicar por 60000 pensando en ms deja timeouts de horas sin tirar ningún error. Ver `idle-screensaver.md` para esta y el resto de las carreras encontradas (bindings que se resetean con la misma actividad que los consulta, decodificación async de video como imagen, arranque con timeout default antes de restaurar el persistido, etc.)
- **Panel `>screensaver` en el launcher** — los sliders fueron reemplazados por tarjetas en 3 columnas con steppers `[−] valor [+]`. Cada stepper muestra "Off" cuando el valor es 0. Los timeouts son ahora **encadenados**: lock = screensaver + N min (no desde última actividad), suspend = screensaver + lock + M min. Primeros componentes reutilizables de slider/toggle del proyecto (`components/controls/Slider.qml`/`Toggle.qml`) — ya no usados en el form pero quedan en components/
- **Dos bugs encontrados probando el panel en vivo, ambos ya corregidos**: (1) si `lockTimeoutMin <= screensaverTimeoutMin` (posible desde que existen los sliders), una carrera entre los dos `IdleMonitor` podía dejar el salvapantallas mostrado para siempre sin pedir nunca la contraseña — fix: `lockMonitor` ahora siempre dispara ≥5s después del salvapantallas sin importar los valores configurados; (2) el sentinel `background = wallpaper` del lockscreen empezó a seguir el fondo del salvapantallas en vez del wallpaper real — fix arriba, sección de lockscreen. Detalle: `idle-screensaver.md` gotchas #14/#15

### Instalación actual
- **Máquina actual**: Dell (Intel HD 520 + AMD Topaz) — en uso hasta recibir la ThinkPad
- **Próxima máquina**: Lenovo ThinkPad X1 Carbon Gen 13 — fresh install con `./bootstrap.sh --no-gpu`
- **Repo en GitHub**: `https://github.com/FreidhYMorales/dotfiles`

---

## Decisiones importantes

| Decisión | Elección | Por qué |
|---|---|---|
| Deploy tool | GNU Stow | Máquina única, sin templating necesario |
| Colores | matugen → colors.json | No convertir a scheme.json — leer nativo en QML |
| Shell | zsh (por ahora) | Migración a fish pendiente de evaluar |
| Bar style | Horizontal top flotante | Monospace/TUI-inspired, pills, Iosevka Term Nerd Font |
| Lock screen | WlSessionLock en Quickshell | Sin hyprlock/swaylock — integrado al escritorio |
| Entry point | install.sh curl-able | Detecta repo / clona; sin clonar primero ni pasos manuales |
| System configs | `system/` (fuera de dotfiles/) | SDDM y GRUB van a /usr/share y /etc — no son Stow |
| WiFi | iwd + impala | NetworkManager eliminado; impala es TUI nativa sin daemon extra |
| SDDM theming dinámico | sddm-theme-sync + sudoers | Matugen necesita escribir a /usr/share como root sin prompt |
| Browser default | Zen Browser | mimeapps.list → `zen.desktop` para http/https/html |
| Web apps | Chromium | `--app=` flag es Chromium-only; Zen (Firefox-based) no lo soporta |

---

## Dinámica de trabajo con Claude

- **El usuario escribe** — Claude no toca archivos salvo pedido explícito.
- **Claude lee bajo pedido** — wiki, referencias, archivos existentes cuando se solicita.
- **Consultas puntuales** — sintaxis Lua de Hyprland, decisiones de estructura, debug.
- **Revisión bajo pedido** — el usuario pasa un archivo si quiere review antes de deployar.

---

## Secrets / Sensibles

- `backup/backups/gnupg/` — claves GPG
- `backup/backups/ssh/` — llaves SSH
- `backup/backups/gh/` — GitHub CLI token
- `~/.config/zsh/secrets.zsh` — API keys (GEMINI_API_KEY) — NO en repo
- `dotfiles/zsh/.config/zsh/secrets.zsh` — template gitignoreado (sin valores)

---

## Reinstalar desde cero

```bash
# Opción A — con repo en disco (disco externo montado)
/ruta/al/disco/Configuraciones/install.sh [--no-gpu]

# Opción B — sin repo en disco (fresh install, con internet)
curl -fsSL https://raw.githubusercontent.com/FreidhYMorales/dotfiles/main/install.sh | bash
# o con flags:
curl -fsSL https://raw.githubusercontent.com/FreidhYMorales/dotfiles/main/install.sh | bash -s -- --no-gpu

# Pasos manuales DESPUÉS del bootstrap (ver sección en el propio bootstrap.sh):
#   1. Restaurar GEMINI_API_KEY en ~/.config/zsh/secrets.zsh
#   2. Restaurar SSH keys desde backup/backups/ssh/
#   3. Restaurar GPG keys desde backup/backups/gnupg/
#   4. Verificar gh auth status (credential helper en .gitconfig)
#   5. Configurar Spicetify con paths correctos de Spotify
#   6. Revisar safe.directory en .gitconfig si cambió la ruta del disco
#   7. grub-install (machine-specific — ver instrucciones en bootstrap.sh step 25)
```

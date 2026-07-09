# Contexto — Disco Externo / Configuraciones

Este directorio vive en un disco externo. Se usa en cada reinstalación de Arch Linux
como fuente de verdad para dotfiles, referencias y memoria de proyecto.

**Usuario:** deadlock — yannelmorales51@gmail.com  
**Stack:** Arch Linux · Hyprland · Quickshell (QML/Qt6) · Neovim · Yazi · zsh  
**GPU:** NVIDIA (ver fixes en backup/references/caelestia/caelestia-patterns-reference.md)

---

## Estructura

```
Configuraciones/
├── CLAUDE.md          ← este archivo
├── dotfiles/          ← repo deployable con GNU Stow (~/Files/Configuraciones/dotfiles/)
│   ├── deploy.sh      ← ./deploy.sh [pkg] [--dry-run]
│   └── ...paquetes/   ← nvim, yazi, zsh, kitty, scripts, etc.
└── backup/            ← backups, referencias, configs anteriores
    ├── references/    ← documentación de referencia (LEER PRIMERO)
    ├── backups/       ← ⚠️ SENSIBLE — gnupg, ssh, gh (gitignoreado)
    ├── archive/       ← configs obsoletas (hypr pre-Omarchy, etc.)
    └── ...configs/    ← nvim, yazi, zsh, kitty, etc. (fuente para dotfiles)
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

### Dotfiles
- Repo en `dotfiles/` con **19 paquetes** deployados con GNU Stow ✅
- `PENDING=()` — todos los paquetes están activos, incluyendo hypr, quickshell y matugen (nuevo)
- `bootstrap.sh` en raíz de dotfiles — instala todas las dependencias + corre deploy.sh. `--no-gpu` salta drivers NVIDIA
- `secrets.zsh` vive en `dotfiles/zsh/.config/zsh/secrets.zsh` (gitignoreado) — restaurar GEMINI_API_KEY manualmente
- `git config --global safe.directory` ya está en `.gitconfig` para las rutas del disco externo
- **Sync manual requerido**: backup/quickshell/ y dotfiles/quickshell/ no están symlinkeados — propagar cambios manualmente

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
- **Theming multi-app activo**: Kitty (live via socket), btop (SIGUSR2), Hyprland borders/shadow (hyprctl reload), Zen Browser (CSS al perfil), Zellij (nueva sesión), **hyprpaper** (reescribe conf + reinicia proceso; si el wallpaper es video extrae primer frame con ffmpeg), **SDDM** (genera `configs/custom.conf` con colores matugen + copia wallpaper a `backgrounds/qs-current.<ext>` via helper privilegiado `/usr/local/bin/sddm-theme-sync`). Post-hook en `~/.config/matugen/post-hook.sh`, llamado desde `Colours.qml` `matugenProc.onExited` (no desde matugen — `run_hook` no funciona en 4.1.0). Usa `python3` para leer `colors.json` (no `jq` — no está instalado en este sistema)
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

#### Bugs corregidos
- **Network.qml flicker**: el Timer reseteaba `connected/signal/ssid` antes de correr el proceso → ícono flickeaba cada 3s. Fix: bufferizar en props privadas del `Process` (`_connected`, `_signal`, `_ssid`) y aplicar todo junto en `onRunningChanged` cuando el proceso termina.

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
- **Panel `>screensaver` en el launcher** (mismo patrón que `>wallpaper`/`>theme`) — expone los 5 campos de `IdleManager.qml` (timeouts + toggle de fondo distinto con picker propio) y un botón de preview en ventana aparte (`modules/screensaver/ScreensaverPreview.qml`) que nunca toca el lock real. Primeros componentes reutilizables de slider/toggle del proyecto (`components/controls/Slider.qml`/`Toggle.qml`)
- **Dos bugs encontrados probando el panel en vivo, ambos ya corregidos**: (1) si `lockTimeoutMin <= screensaverTimeoutMin` (posible desde que existen los sliders), una carrera entre los dos `IdleMonitor` podía dejar el salvapantallas mostrado para siempre sin pedir nunca la contraseña — fix: `lockMonitor` ahora siempre dispara ≥5s después del salvapantallas sin importar los valores configurados; (2) el sentinel `background = wallpaper` del lockscreen empezó a seguir el fondo del salvapantallas en vez del wallpaper real — fix arriba, sección de lockscreen. Detalle: `idle-screensaver.md` gotchas #14/#15

### Instalación actual
- Sistema reinstalado limpio ✅
- Entorno activo: monasm-dots (EWW + Hyprland) — corriendo como referencia visual
- Dotfiles propios deployados (hypr y quickshell en PENDING hasta tener config propia)

---

## Decisiones importantes

| Decisión | Elección | Por qué |
|---|---|---|
| Deploy tool | GNU Stow | Máquina única, sin templating necesario |
| Colores | matugen → colors.json | No convertir a scheme.json — leer nativo en QML |
| Shell | zsh (por ahora) | Migración a fish pendiente de evaluar |
| Bar style | Horizontal top flotante | Monospace/TUI-inspired, pills, Iosevka Term Nerd Font |
| Lock screen | WlSessionLock en Quickshell | Sin hyprlock/swaylock — integrado al escritorio |

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

## Comandos útiles al reinstalar

```bash
# 1. Instalar dependencias base
sudo pacman -S --needed git base-devel stow

# 2. Instalar yay
git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si

# 3. Instalar paquetes del sistema (ver packages-reference.md para lista completa)

# 4. Instalar Oh My Zsh (antes del deploy de dotfiles)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 5. Clonar plugins de zsh en OMZ custom
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/chrissicool/zsh-256color ~/.oh-my-zsh/custom/plugins/zsh-256color
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions

# 6. Deploy dotfiles con Stow
cd ~/Files/Configuraciones/dotfiles && ./deploy.sh --dry-run  # verificar
./deploy.sh

# 7. Restaurar secrets
cp ~/Files/Configuraciones/backup/backups/gnupg/* ~/.gnupg/
cp ~/Files/Configuraciones/backup/backups/ssh/* ~/.ssh/
echo 'export GEMINI_API_KEY="..."' > ~/.config/zsh/secrets.zsh

# 8. Post-nvim: instalar magick para snacks.image
luarocks install magick

# 9. Instalar plugins de yazi (ver packages-reference.md sección 7)
```

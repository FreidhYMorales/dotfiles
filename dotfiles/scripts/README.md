# scripts

Utilidades en `.local/bin/`, deployadas a `~/.local/bin/` por Stow (sin symlinks manuales).

**`~/.local/bin` en el PATH de los keybinds**: el paquete `uwsm` (`~/.config/uwsm/env`) agrega `~/.local/bin` al PATH de la sesión gráfica — sin esto, estos scripts resuelven bien desde una zsh interactiva (PATH seteado en `.zshrc`/`.zshenv`) pero fallan en silencio (`command not found`) al ser lanzados directo por Hyprland/UWSM vía keybind, que no leen esos archivos de shell.

Se probó primero con `~/.config/environment.d/` (mecanismo estándar de systemd) — no funcionó: UWSM levanta Hyprland a través de su propio preloader de entorno (`wayland-wm-env@hyprland.desktop.service` → `/usr/lib/uwsm/prepare-env.sh`), que sourcea `/etc/profile`/`~/.profile` y reexporta `PATH` DESPUÉS de que corren los generadores de systemd — pisando por completo lo que haya armado `environment.d`. Confirmado en vivo leyendo `/proc/<pid de Hyprland>/environ` incluso después de un reboot real. `~/.config/uwsm/env` es cargado por ese mismo preloader (`load_wm_env`, después del bloque de `/etc/profile`), así que es la última palabra real sobre el entorno de la sesión.

Requiere logout/login para tomar efecto — el preloader de UWSM corre una vez por sesión, no hay forma de recargarlo con `hyprctl reload` ni reiniciando el compositor.

## clipboard

Historial de clipboard con modo delete para eliminar entradas sensibles.

**Deps:** `cliphist`, `wl-clipboard`, `fuzzel` (todas en `bootstrap.sh`)

```bash
clipboard           # buscar y pegar del historial
clipboard --delete  # eliminar entradas (útil para contraseñas, tokens)
```

El historial en sí (`SUPER+V`) usa un pipeline directo `cliphist | fuzzel | wl-copy` en `keybinds.lua`, no este script. `SUPER+SHIFT+V` → `clipboard --delete`.

## launch-or-focus

Si la app ya está abierta en Hyprland, la enfoca. Si no, la lanza.

**Deps:** `jq` (hyprctl ya viene con Hyprland)

```bash
launch-or-focus firefox
launch-or-focus thunar "uwsm-app -- thunar"   # comando de launch custom
```

El patrón se matchea (case-insensitive, word boundary) contra la clase y el título de la ventana. Hoy solo aplicado a `SUPER+B` (browser) en `keybinds.lua`.

## mute-toggle

Togglea mute del sink/source default y sincroniza el LED de mute del ThinkPad
(`thinkpad_acpi`) con el estado real.

**Por qué existe:** PipeWire mutea a nivel de stream en esta tarjeta
(SOF/SoundWire) — nunca flippea el switch ALSA (`Speaker Playback Switch`)
que el trigger `audio-mute`/`audio-micmute` del kernel (`snd_ctl_led`) escucha,
así que el LED nunca prendía aunque el mute funcionara bien. Confirmado en
vivo con `amixer -c0 sget Speaker` — el switch queda en `[on]` sin importar
el estado de `wpctl`.

**Deps:** `wpctl`. Requiere la regla udev `system/udev/rules.d/92-mute-leds.rules`
deployada (`uaccess` sobre los nodos LED — sin ella, el `echo > brightness`
falla en silencio por permisos).

```bash
mute-toggle output   # toggle + sync platform::mute
mute-toggle input    # toggle + sync platform::micmute
```

Binds: `XF86AudioMute` → `mute-toggle output`, `XF86AudioMicMute` → `mute-toggle input`
(`keybinds.lua`). También usado por `Audio.qml`'s `toggleMute()` (click en el
slider de volumen del OSD).

## ocr

Seleccionás una región de la pantalla, extrae el texto con tesseract y lo copia al clipboard.

**Deps:** `grim`, `slurp`, `hyprpicker`, `tesseract`, `tesseract-data-<idioma>`, `wl-clipboard`

```bash
ocr   # seleccionás la región → el texto queda en clipboard
```

| Variable | Default | Descripción |
|---|---|---|
| `OCR_LANGS` | `eng` | Idioma(s) de tesseract. Múltiples: `eng+spa` |

Bind: `SUPER+O`.

## reminder

Recordatorios via systemd user timers. Sin daemon, sin proceso en background.

**Deps:** `systemd` (user session), `libnotify`. Usa `notification-send` (script hermano en este mismo paquete).

```bash
reminder 30 "Revisar el horno"   # recordatorio en 30 minutos
reminder 5                        # recordatorio genérico en 5 minutos
reminder show                     # listar recordatorios activos con tiempo restante
reminder clear                    # cancelar todos
```

Bind: `SUPER+R` → `reminder show`.

## record

Toggle de grabación de pantalla con `gpu-screen-recorder`. Soporta pausa/resume via señal.

**Deps:** `gpu-screen-recorder-git` (AUR), `slurp`, `jq`

```bash
record              # toggle: inicia si no graba, detiene y guarda si graba
record --pause      # pausa/reanuda grabación en curso (SIGUSR2)
record --region     # seleccionar región con slurp antes de grabar
record --sound      # incluir audio del sistema
```

| Variable | Default | Descripción |
|---|---|---|
| `RECORDING_DIR` | `~/Videos/Recordings` | Dónde guardar las grabaciones |

**Sin keybind** — redundante con `RecorderWidget` nativo de Quickshell (bar), que ya cubre grabación de pantalla completa/región/ventana con auto-detección de GPU. Queda disponible para uso manual desde terminal si hace falta.

## screenshot

Screenshot con selección inteligente — si el área seleccionada es < 20px², snapea automáticamente a la ventana o monitor más cercano.

**Deps:** `grim`, `slurp`, `hyprpicker`, `wl-clipboard`, `satty` (AUR)

```bash
screenshot              # modo smart (default) — guarda + copia + ofrece editor
screenshot region       # selección libre
screenshot windows      # snapea a ventanas/monitores
screenshot fullscreen   # monitor enfocado completo
screenshot smart copy   # solo al clipboard, sin guardar
screenshot smart save   # solo guarda, sin clipboard
screenshot smart slurp --editor=gimp  # editor custom
```

| Variable | Default | Descripción |
|---|---|---|
| `SCREENSHOT_DIR` | `$XDG_PICTURES_DIR` | Dónde guardar |
| `SCREENSHOT_EDITOR` | `satty` | Editor al hacer clic en la notificación |

Binds: `PRINT` → `screenshot fullscreen`, `SUPER+PRINT` → `screenshot region`. `SUPER+SHIFT+PRINT` (captura instantánea de la ventana activa, sin interacción) sigue usando `grim`/`jq` crudo — el script no tiene un modo equivalente sin click.

## notification-send

Envoltorio de `notify-send` con formato uniforme: glifo + título, y descripción indentada.

**Deps:** `libnotify` (`notify-send`). Usado por `reminder`.

```bash
notification-send "󰔛" "Recordatorio" "Revisar el horno" -u critical
```

## webapp-install

Crea un lanzador `.desktop` para una web app, con ícono descargado del servicio de favicons de Google.

**Deps:** `curl`; `gum` opcional para el modo interactivo.

```bash
webapp-install                          # interactivo (nombre + URL)
webapp-install WhatsApp web.whatsapp.com
```

También lo llama el comando `>webapp` del launcher de Quickshell (`WebAppForm.qml`).

## webapp-launch

Abre una URL como app independiente (`--app=`) en el navegador por defecto si es Chromium-based; si no (Zen), usa `chromium`. Es el `Exec=` de los `.desktop` que genera `webapp-install`.

**Deps:** `xdg-settings`, `uwsm-app`, `chromium`

## webapp-remove

Borra el lanzador y el ícono de una o varias web apps.

**Deps:** `gum` opcional para elegir de la lista.

```bash
webapp-remove            # interactivo
webapp-remove WhatsApp
```

## webapp-restore

Instala todas las web apps declaradas en `~/.local/share/webapps/apps` (formato `nombre | url [| ícono]`), salteando las que ya tienen `.desktop`. Lo corre `bootstrap.sh` después del deploy.

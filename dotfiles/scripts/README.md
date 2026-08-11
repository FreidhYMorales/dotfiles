# scripts

Utilidades en `.local/bin/`, deployadas a `~/.local/bin/` por Stow (ya en `PATH`, sin symlinks manuales).

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

## wsaction

Navegación de workspaces en grupos de 10. Workspace 1-10 = grupo 1, 11-20 = grupo 2, etc.

**Deps:** `fish`, `jq`

```bash
wsaction workspace 1        # ir al workspace 1 del grupo actual
wsaction workspace 5        # ir al workspace 5 del grupo actual
wsaction -g workspace 1     # saltar al mismo slot en el grupo siguiente
```

**Sin keybind** — disponible pero no adoptado como flujo de trabajo actual.

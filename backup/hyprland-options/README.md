# hyprland-options

Opciones de Hyprland extraídas de Caelestia. Son referencias para integrar en tu config existente, no archivos para instalar directamente.

## Archivos

### `misc.conf`
Opciones del bloque `misc {}`. Las más importantes:
- `middle_click_paste = false` — elimina paste accidental con botón del medio
- `session_lock_xray = true` — fondo desenfocado al bloquear (no negro)
- `vrr = 1` — Variable Refresh Rate si el monitor lo soporta

Integrar en `~/.config/hypr/hyprland.conf` o en un archivo sourced.

### `gestures.conf`
Gestos de touchpad (requiere Hyprland >= 0.41):
- 4 dedos horizontal → cambiar workspace
- 3 dedos arriba → abrir special workspace
- 4 dedos abajo → `systemctl suspend-then-hibernate`

Integrar en `~/.config/hypr/hyprland.conf`.

### `autostart.conf`
Entradas `exec-once` útiles:
- `wl-paste --watch cliphist store` (×2, texto e imágenes) — historial de clipboard
- `trash-empty 30` — limpieza automática de papelera
- `mpris-proxy` — controles BT de auriculares funcionan con tu reproductor MPRIS

Deps: `trash-cli` (`pacman -S trash-cli`), `cliphist` (`pacman -S cliphist`).

# clipboard

Historial de clipboard con modo delete para eliminar entradas sensibles.

## Deps

```bash
sudo pacman -S cliphist wl-clipboard fuzzel
```

Requiere autostart en Hyprland (ver `hyprland-options/autostart.conf`):
```
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```

## Instalar

```bash
ln -sf ~/Files/Configuraciones/clipboard/scripts/clipboard ~/.local/bin/
```

## Uso

```bash
clipboard           # buscar y pegar del historial
clipboard --delete  # eliminar entradas (útil para contraseñas, tokens)
```

## Hyprland bindings sugeridos

```
bind = SUPER, V, exec, clipboard
bind = SUPER SHIFT, V, exec, clipboard --delete
```

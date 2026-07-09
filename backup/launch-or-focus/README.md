# launch-or-focus

Si la app ya está abierta en Hyprland, la enfoca. Si no, la lanza. Hace los keybindings más limpios.

## Deps

```bash
sudo pacman -S jq   # hyprctl ya está incluido en Hyprland
```

## Instalar

```bash
ln -sf ~/Files/Configuraciones/launch-or-focus/scripts/launch-or-focus ~/.local/bin/
```

## Uso

```bash
launch-or-focus firefox
launch-or-focus thunar "uwsm-app -- thunar"   # comando de launch custom
```

El patrón se matchea (case-insensitive, word boundary) contra la clase y el título de la ventana en Hyprland.

## Hyprland bindings sugeridos

```
bind = SUPER, B, exec, launch-or-focus zen-browser
bind = SUPER, E, exec, launch-or-focus thunar "uwsm-app -- thunar"
bind = SUPER, M, exec, launch-or-focus ncmpcpp "xdg-terminal-exec -e ncmpcpp"
```

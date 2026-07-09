# workspace-groups

Navegación de workspaces en grupos de 10. Workspace 1-10 = grupo 1, 11-20 = grupo 2, etc.

## Deps

```bash
sudo pacman -S fish jq
```

## Instalar

```bash
ln -sf ~/Files/Configuraciones/workspace-groups/scripts/wsaction ~/.local/bin/
```

## Uso

```bash
wsaction workspace 1        # ir al workspace 1 del grupo actual
wsaction workspace 5        # ir al workspace 5 del grupo actual
wsaction -g workspace 1     # saltar al mismo slot en el grupo siguiente
```

## Hyprland bindings sugeridos

```
# Navegar dentro del grupo actual
bind = SUPER, 1, exec, wsaction workspace 1
bind = SUPER, 2, exec, wsaction workspace 2
# ... hasta 9/0

# Saltar entre grupos
bind = SUPER CTRL, right, exec, wsaction -g workspace 1
bind = SUPER CTRL, left,  exec, wsaction -g workspace 10

# Mover ventana a workspace del grupo actual
bind = SUPER SHIFT, 1, exec, wsaction movetoworkspace 1
```

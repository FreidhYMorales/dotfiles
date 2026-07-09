# screenshots

Screenshot con selección inteligente — si el área seleccionada es < 20px², snapa automáticamente a la ventana o monitor más cercano.

## Deps

```bash
sudo pacman -S grim slurp hyprpicker wl-clipboard
yay -S satty
```

## Instalar

```bash
ln -sf ~/Files/Configuraciones/screenshots/scripts/screenshot ~/.local/bin/
```

## Uso

```bash
screenshot              # modo smart (default) — guarda + copia + ofrece editor
screenshot region       # selección libre
screenshot windows      # snapa a ventanas/monitores
screenshot fullscreen   # monitor enfocado completo
screenshot smart copy   # solo al clipboard, sin guardar
screenshot smart save   # solo guarda, sin clipboard
screenshot smart slurp --editor=gimp  # editor custom
```

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `SCREENSHOT_DIR` | `$XDG_PICTURES_DIR` | Dónde guardar |
| `SCREENSHOT_EDITOR` | `satty` | Editor al hacer clic en la notificación |

## Hyprland binding sugerido

```
bind = , Print, exec, screenshot
bind = SHIFT, Print, exec, screenshot region
bind = SUPER, Print, exec, screenshot fullscreen
```

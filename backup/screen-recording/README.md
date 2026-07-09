# screen-recording

Toggle de grabación de pantalla con gpu-screen-recorder. Soporta pausa/resume via señal.

## Deps

```bash
yay -S gpu-screen-recorder-git
sudo pacman -S slurp jq
```

## Instalar

```bash
ln -sf ~/Files/Configuraciones/screen-recording/scripts/record ~/.local/bin/
```

## Uso

```bash
record              # toggle: inicia si no graba, detiene y guarda si graba
record --pause      # pausa/reanuda grabación en curso (SIGUSR2)
record --region     # seleccionar región con slurp antes de grabar
record --sound      # incluir audio del sistema
```

Al detener, muestra notificación con acciones: Ver / Abrir carpeta / Eliminar.

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `RECORDING_DIR` | `~/Videos/Recordings` | Dónde guardar las grabaciones |

## Hyprland bindings sugeridos

```
bind = SUPER SHIFT, R, exec, record
bind = SUPER ALT, R,   exec, record --pause
bind = SUPER CTRL, R,  exec, record --region --sound
```

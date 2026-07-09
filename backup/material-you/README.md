# material-you

Temas dinámicos desde el wallpaper. **Herramienta elegida: matugen.**

## Estado: PENDIENTE

Falta conectar matugen con el hook y adaptar los templates al formato de matugen.

## Herramienta

```bash
yay -S matugen
```

Repo: https://github.com/InioX/matugen

## Cómo funciona

```
wallpaper cambia
    → matugen image /ruta/wallpaper.jpg
        → regenera todos los archivos en templates/
        → llama post-hook.sh con las variables de entorno
            → post-hook hace acciones custom (reiniciar waybar, notificar, etc.)
```

## Formato de templates (matugen)

Los templates de la carpeta `templates/` están en formato Caelestia (`{{ $primary }}`).
Hay que adaptarlos al formato de matugen: `{{colors.primary.hex}}`.

Ver la documentación de matugen para todos los tokens disponibles:
- `{{colors.primary.hex}}` — color primario en hex
- `{{colors.surface.hex}}` — superficie
- `{{scheme}}` — "dark" o "light"

## post-hook.sh

Script que se ejecuta después de que matugen regenera los templates.
Usar para: reiniciar servicios, aplicar colores a apps que no usan archivos,
enviar señales (btop con SIGUSR2, terminales via /dev/pts), etc.

## Integración con swww / hyprpaper

Con swww, el cambio de wallpaper puede disparar matugen automáticamente:
```bash
# En el script de cambio de wallpaper:
swww img /ruta/wallpaper.jpg
matugen image /ruta/wallpaper.jpg
~/.config/matugen/post-hook.sh
```

## Próximos pasos

1. Adaptar templates al formato de matugen (`{{colors.X.hex}}`)
2. Configurar matugen en `~/.config/matugen/config.toml` apuntando a los templates
3. Integrar con el script de cambio de wallpaper (swww/hyprpaper)
4. Completar `post-hook.sh` con las acciones específicas del setup

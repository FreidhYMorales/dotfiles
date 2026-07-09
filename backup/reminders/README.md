# reminders

Recordatorios via systemd user timers. Sin daemon, sin proceso en background.

## Deps

`systemd` (ya instalado) + `libnotify` para `notify-send`.

`notification-send` es un wrapper interno incluido en este folder — instalar junto con `reminder`.

## Instalar

```bash
ln -sf ~/Files/Configuraciones/reminders/scripts/reminder          ~/.local/bin/
ln -sf ~/Files/Configuraciones/reminders/scripts/notification-send ~/.local/bin/
```

## Uso

```bash
reminder 30 "Revisar el horno"   # recordatorio en 30 minutos
reminder 5                        # recordatorio genérico en 5 minutos
reminder show                     # listar recordatorios activos con tiempo restante
reminder clear                    # cancelar todos
```

## Hyprland binding sugerido

```
bind = SUPER, R, exec, reminder show
```

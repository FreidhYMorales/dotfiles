# Quickshell

Shell propio para Arch Linux + Hyprland. Qt6/QML, estética TUI-inspired, Material 3.

## Documentación

Ver carpeta [`docs/`](./docs/):

- [index.md](./docs/index.md) — overview y stack
- [architecture.md](./docs/architecture.md) — patrones, IPC, animaciones
- [services.md](./docs/services.md) — Colours, Time, Battery, Audio, SysInfo, Mpris, NotifStore, Visibilities
- [bar.md](./docs/bar.md) — barra superior y todos sus widgets
- [dashboard.md](./docs/dashboard.md) — panel de control + todas las secciones
- [launcher.md](./docs/launcher.md) — app launcher con animación multi-stage
- [notifications.md](./docs/notifications.md) — panel notif/calendario/clima
- [components.md](./docs/components.md) — CAnim, Anim, utils, scripts
- [gotchas.md](./docs/gotchas.md) — errores conocidos de QML/Quickshell
- [roadmap.md](./docs/roadmap.md) — estado actual y pendiente por fase
- [lockscreen.md](./lockscreen.md) — lock screen, port visual del theme SDDM "silent"
- [idle-screensaver.md](./idle-screensaver.md) — salvapantallas, auto-bloqueo, auto-suspensión, modo caffeine
- [wallpaper-theming.md](./wallpaper-theming.md) — wallpaper picker + theming-mode picker
- [recorder.md](./recorder.md) — screen recorder (gpu-screen-recorder)

## Correr

```bash
qs -p /home/deadlock/Mio/Configuraciones/backup/quickshell
```

## Instalación

```bash
yay -S quickshell-git
```

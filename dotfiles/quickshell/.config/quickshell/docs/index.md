# Quickshell — Índice de documentación

Shell propio para Arch Linux + Hyprland, construido en Quickshell (Qt6/QML).  
Estética TUI-inspired, pills flotantes, Material 3. Paleta dinámica vía matugen.

---

## Documentos

| Archivo | Contenido |
|---|---|
| [architecture.md](./architecture.md) | Arquitectura general, patrones, cómo se conectan los módulos |
| [services.md](./services.md) | Todos los singletons de datos del sistema |
| [bar.md](./bar.md) | Barra superior y todos sus widgets |
| [dashboard.md](./dashboard.md) | Panel de control derecho y todas sus secciones |
| [launcher.md](./launcher.md) | App launcher con animación por stages |
| [notifications.md](./notifications.md) | Panel notificaciones / calendario / clima |
| [components.md](./components.md) | Componentes reutilizables, utils y scripts |
| [gotchas.md](./gotchas.md) | Errores conocidos, pitfalls de QML/Quickshell |
| [roadmap.md](./roadmap.md) | Estado actual y pendiente por fase |
| [../lockscreen.md](../lockscreen.md) | Lock screen — port visual del theme SDDM "silent" |
| [../idle-screensaver.md](../idle-screensaver.md) | Salvapantallas, auto-bloqueo, auto-suspensión, modo caffeine |
| [../wallpaper-theming.md](../wallpaper-theming.md) | Wallpaper picker + theming-mode picker |
| [../recorder.md](../recorder.md) | Screen recorder (gpu-screen-recorder) |

---

## Cómo correr

```bash
# Desarrollo
qs -p /home/deadlock/Mio/Configuraciones/backup/quickshell

# Producción (autostart Hyprland)
exec-once = uwsm-app -- qs -p ~/Files/Configuraciones/quickshell
```

## Stack

- **Runtime**: Quickshell (Qt6/QML) — `yay -S quickshell-git`
- **Compositor**: Hyprland (Wayland)
- **Fuente**: Iosevka Term Nerd Font
- **Colores**: matugen → `~/.config/matugen/colors.json` → `Colours` singleton
- **IPC con Hyprland**: `Quickshell.Hyprland` + `CustomShortcut`

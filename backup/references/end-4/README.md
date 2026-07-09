# Referencias — end-4/dots-hyprland

Fuente: https://github.com/end-4/dots-hyprland

## Documentación de arquitectura (Quickshell)

| Archivo | Contenido |
|---|---|
| [`ii-shell-architecture.md`](ii-shell-architecture.md) | Arquitectura general: entry point, panel family system, GlobalStates, visibilidad de paneles, Config/Persistent, Directories, namespaces, servicios |
| [`ii-quickshell-patterns.md`](ii-quickshell-patterns.md) | Patterns QML concretos: sistema de colores, AnimatedTabIndexPair, tab system, bar, notificaciones, lock screen, animation system, widgets, Waffle family |
| [`ii-patterns-reference.md`](ii-patterns-reference.md) | Hyprland: IPC, keybinds, Lua config, bezier curves, animation assignments, blur, layer rules, window rules |
| [`ii-tools-reference.md`](ii-tools-reference.md) | Stack de herramientas: paquetes core/opcional, fuentes, theming, startup order |

---

## Contenido

### `shaders/`
| Archivo | Descripción |
|---|---|
| `anti-flashbang.glsl` | Shader fuerte: mide brillo promedio (grilla 10×10) y aplica overlay negro. Opacity = brightness × 0.75 |
| `anti-flashbang-weak.glsl` | Versión suave: misma lógica, opacity = brightness × 0.42. Para uso diurno. |

**Activar desde Quickshell:**
```qml
HyprlandConfig.setMany({
    "decoration:screen_shader": Qt.resolvedUrl("shaders/anti-flashbang.glsl"),
    "debug:damage_tracking": 1   // ← necesario con NVIDIA para evitar flashes
})
```

**O directamente desde Hyprland:**
```
decoration {
    screen_shader = /ruta/anti-flashbang.glsl
}
debug {
    damage_tracking = 1
}
```

### `quickshell/`
| Archivo | Descripción |
|---|---|
| `HyprlandAntiFlashbangShader.qml` | Servicio que controla el shader: enable/disable/toggle/cycle (3 estados) |
| `HyprlandConfig.qml` | Servicio para modificar config de Hyprland en runtime sin reload manual. Escribe en `shellOverrides/main.lua` |
| `Cliphist.qml` | Servicio de cliphist con IPC handler. Elimina el polling — se actualiza en tiempo real vía `qs ipc call cliphistService update` |

**Patrón clave de Cliphist + IPC en autostart:**
```lua
-- En execs.lua de Hyprland, reemplazar el wl-paste --watch simple por:
exec-once = wl-paste --type text  --watch bash -c "cliphist store; qs ipc call cliphistService update"
exec-once = wl-paste --type image --watch bash -c "cliphist store; qs ipc call cliphistService update"
```

### `scripts/`
| Archivo | Descripción |
|---|---|
| `primary-buffer-ai.sh` | Manda la selección primaria de Wayland (texto seleccionado sin Ctrl+C) a Ollama local. Responde por notify-send. |
| `snip-to-google-lens.sh` | Captura región con slurp, sube a uguu.se, abre Google Lens en el browser. |

### `hyprland-rules.lua`
Window/layer rules completas con comentarios explicativos. Las más importantes:

- **`move = {999999, 999999}`** — ocultar ventanas sin matarlas (más confiable que `nofocus`)
- **PiP** — esquina inferior derecha al 25% del monitor con `keep_aspect_ratio + pin`
- **Screen sharing** — indicador centrado horizontalmente, pegado al fondo del monitor
- **Tearing selectivo** — `immediate = true` solo para `.exe`, `steam_app_*`, Minecraft
- **`quickshell:popup` → `xray = false` + `ignore_alpha = 1`** — fix crítico para colores raros en tooltips de Quickshell
- **Animaciones por namespace** — cada surface de Quickshell tiene su propia animación

## Dependencias de los scripts

```bash
# primary-buffer-ai.sh
sudo pacman -S ollama  # o yay -S ollama
# Tener al menos un modelo cargado: ollama run llama3.2

# snip-to-google-lens.sh
sudo pacman -S grim slurp curl jq  # grim/slurp ya instalados
```

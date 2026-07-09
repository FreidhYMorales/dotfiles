# ii — Stack de Herramientas

Stack completo del ii framework explorado live en 2026-06-04.
Separado en core (sin esto no funciona) y opcional (mejoras o casos específicos).

---

## Core — sin esto el sistema no arranca

| Herramienta | Rol | Paquete AUR/pacman |
|---|---|---|
| Hyprland | WM / compositor Wayland | `hyprland` |
| Quickshell | Bar + sidebars + notificaciones + lock + todo | `quickshell-git` |
| foot | Terminal principal | `foot` |
| fish | Shell CLI | `fish` |
| fuzzel | Launcher | `fuzzel` |
| matugen | Generador de colores M3 desde wallpaper | `matugen` |
| pipewire | Audio | `pipewire pipewire-pulse` |
| wireplumber | Session manager de PipeWire | `wireplumber` |
| cliphist | Historial de clipboard | `cliphist` |
| wl-clipboard | Clipboard Wayland (wl-paste, wl-copy) | `wl-clipboard` |
| hypridle | Idle daemon (lock + DPMS + suspend) | `hypridle` |
| hyprlock | Lock screen (fallback, QS tiene el suyo) | `hyprlock` |
| grim | Capturas de pantalla Wayland | `grim` |
| slurp | Selector de región para capturas | `slurp` |
| playerctl | Control de MPRIS (música, media) | `playerctl` |
| xdg-desktop-portal-hyprland | Portal de escritorio para screen sharing / file picker | `xdg-desktop-portal-hyprland` |

---

## Fuentes — sin estas el UI de Quickshell queda en blanco

| Fuente | Rol | Instalación |
|---|---|---|
| Google Sans Flex | UI principal (variable, 6 ejes) | Submodulo git en ii / manual |
| JetBrains Mono NF | Terminal + iconos Nerd | `ttf-jetbrains-mono-nerd` |
| Material Symbols Rounded | Iconos dentro de Quickshell | `ttf-material-symbols-variable-git` |
| Readex Pro | Lectura / párrafos | `ttf-readex-pro` o manual |
| Space Grotesk | Headings expresivos | `ttf-space-grotesk` o manual |

> Instalar ANTES del primer inicio de Quickshell. Si las fuentes faltan, todo el UI se renderiza en blanco.

---

## Theming — para el pipeline de colores dinámicos

| Herramienta | Rol | Paquete |
|---|---|---|
| matugen | Genera paleta M3 desde wallpaper → JSON + CSS | `matugen` |
| kde-material-you-colors | Aplica accent color a Qt/KDE/iconos | `kde-material-you-colors` + Python venv |
| Kvantum | Engine de temas Qt | `kvantum` |
| kvantum-theme-material-ocean | Tema base Kvantum | AUR |
| breeze-plus / breeze-plus-dark | Iconos (switch automático dark/light) | AUR |
| Bibata-Modern-Classic | Cursor | `bibata-cursor-theme` |

**Bootstrap order — crítico:**
```
1. matugen apply --wallpaper <path>     # genera color.txt + colors.json
2. kde-material-you-colors              # lee color.txt → aplica Qt theme
```
Si `color.txt` no existe, kde-material-you-colors falla silenciosamente.

---

## Opcional — mejoras de calidad de vida

| Herramienta | Rol | Sin esto |
|---|---|---|
| hyprshot | Screenshots mejoradas (coordenadas relativas) | usar grim+slurp directamente |
| hyprpicker | Color picker de pantalla | — |
| tesseract | OCR de región a texto/clipboard | sin OCR |
| easyeffects | Efectos de audio (EQ, compressor) | audio sin procesamiento |
| starship | Prompt del terminal | prompt por defecto |
| fastfetch | Fetch info del sistema | — |
| btop | Monitor de recursos TUI | htop o similar |
| geoclue | Ubicación del sistema (para theming basado en hora) | sin location-aware features |

---

## Opcional — apps específicas de ii

| Herramienta | Rol | Nota |
|---|---|---|
| mpvpaper | Wallpaper animado (video) | alto consumo CPU/GPU |
| kde-material-you-colors | Qt theming | heavy setup, solo si necesitás Qt |
| geoclue | Location services | solo para theming por hora del día |
| gnome-keyring | Keyring para credenciales | alternativa: kwallet |

---

## NO replicar de ii

| Herramienta | Por qué omitir |
|---|---|
| Todo el Python venv de kde-material-you-colors | Setup pesado, solo para Qt. Si no usás apps Qt, innecesario |
| mpvpaper (video wallpaper) | Consumo de recursos alto. Wallpaper estático es suficiente |
| WinApps | Muy específico (KVM + RDP para Windows). Setup propio |
| 5 plugins de AI en Neovim simultáneos | Elegir 1-2: claudecode para agente, codecompanion para chat |
| geoclue agent | Solo necesario si querés theming por hora solar |

---

## Startup — orden de execs en ii

```
1. geoclue-agent.sh         # location services (opcional)
2. qs -c ii                 # Quickshell — lanzar primero
3. __restore_video_wallpaper.sh  # user custom (opcional)
4. gnome-keyring-daemon
5. hypridle
6. dbus-update-activation-environment (×2)
7. easyeffects --service-mode
8. wl-paste --watch → cliphist + qs ipc call (clipboard sync)
```

> Quickshell debe estar arriba antes de que los wl-paste watchers intenten
> hacer IPC. Si se invierte el orden, el primer evento de clipboard falla.

---

## Gestores de paquetes usados en ii

- `pacman` — paquetes del sistema
- `yay` o `paru` — AUR helpers
- `ya pack` — plugins de Yazi
- Python venv en `~/.local/state/quickshell/.venv/` — kde-material-you-colors

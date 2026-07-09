# Configuraciones

Backup de configuraciones personales — Arch Linux.  
Última snapshot: 2026-05-18 | Usuario: `yannelmorales51@gmail.com`

> Este repo es una **referencia y punto de partida**, no un dotfiles listo para instalar.
> La restauración completa ocurre cuando empiece a construir mis propios dotfiles.
> Para comandos de instalación paso a paso: ver [RESTORE.md](RESTORE.md).

---

## Estado actual del sistema

| Componente | Herramienta activa | Estado config |
|---|---|---|
| WM | Hyprland (via Omarchy/ii) | ✅ activo |
| Shell bar | Quickshell (ii framework) | ✅ activo |
| Terminal | foot (primary), kitty (secondary) | ✅ activo |
| Shell CLI | fish + Starship | ✅ activo |
| Editor | Neovim (lazy.nvim) | ✅ activo |
| File manager | Yazi | ✅ activo |
| Browser | Zen Browser | ✅ activo |
| Theming | matugen (pendiente bootstrap) | ⚠️ sin correr |
| Shell propia | — | 🔧 en planeación |

---

## Estructura del repo

```
Configuraciones/
│
├── RESTORE.md              # Guía completa de restauración por fases
├── references/             # Dotfiles de referencia para mis propios dots
│
├── backups/                # ⚠️ SENSIBLE — en .gitignore, nunca pushear
│   ├── gnupg/              # Claves GPG exportadas (.asc)
│   ├── ssh/                # Llaves SSH (privada + pública)
│   └── gh/                 # GitHub CLI auth (contiene token)
│
├── archive/                # Configs viejas/obsoletas, solo por si acaso
│   ├── hypr-pre-omarchy/   # Config Hyprland/Caelestia era anterior
│   ├── restorations/       # Scripts de restore de setups previos
│   └── mysql/              # Config MySQL de setup anterior
│
├── — Identidad —
├── git/                    # .gitconfig
│
├── — Shell —
├── zsh/                    # zsh (OMZ + Zinit + funciones + aliases)
├── starship/               # Starship prompt
│
├── — Editor —
├── nvim/                   # Neovim (lazy.nvim, 50+ plugins, tema Night Wolf)
│                           # Ver nvim/CLAUDE.md y nvim/CONTEXT/ para documentación
│
├── — File manager —
├── yazi/                   # Yazi (14+ plugins, activado via YAZI_CONFIG_HOME)
│                           # Ver yazi/CONTEXT/ y yazi/docs/ para documentación
│
├── — WM / Compositor —
├── omarchy/                # Overrides de Omarchy (fuente actual del WM)
├── hyprland-options/       # Opciones Hyprland (autostart, gestures, misc)
│
├── — Terminal —
├── kitty/                  # Kitty (secundario en Omarchy)
│
├── — Browser —
├── zen/                    # Zen Browser (perfil completo con mods Sine)
│
├── — Música —
├── mpd/                    # MPD (servidor de música)
├── ncmpcpp/                # ncmpcpp (cliente TUI)
├── spicetify/              # Spicetify (Spotify theming)
│
├── — Comunicación —
├── vesktop/                # Vesktop + Vencord (Discord)
├── BetterDiscord/          # BetterDiscord plugins/themes
│
├── — Sistema —
├── fonts/                  # Fuentes instaladas manualmente
├── mimeapps.list           # Aplicaciones por defecto por MIME type
├── obsidian/               # Registro de vaults de Obsidian
├── fastfetch/              # Fastfetch + logos
├── btop/                   # btop (monitor de recursos)
├── wiremix/                # wiremix (mixer de audio TUI)
├── hardware/               # Scripts GPU/CPU, batería, brillo
├── systemd/                # Units de systemd usuario
├── winapps/                # WinApps (Office via RDP/libvirt)
├── w3m/                    # w3m browser config
│
├── — Features / Scripts —
├── screenshots/            # Screenshots smart/region/windows/fullscreen
├── ocr/                    # OCR de región a clipboard
├── reminders/              # Recordatorios via systemd user timers
├── clipboard/              # Historial clipboard con modo delete
├── screen-recording/       # Grabación con pause/resume
├── webapps/                # Web apps declarativas (lista + restore script)
├── launch-or-focus/        # Lanzar app o enfocar ventana existente
├── workspace-groups/       # Workspaces en grupos de 10
├── xcompose/               # Emojis y tipografía via XCompose
│
├── — En construcción —
├── quickshell/             # Shell/bar propio (solo arquitectura planificada)
└── material-you/           # Theming dinámico (matugen elegido, templates pendientes)
```

---

## Features — scripts propios

Cada carpeta es autocontenida con su propio README de deps + uso.

| Carpeta | Qué hace | Estado |
|---|---|---|
| [`screenshots/`](screenshots/README.md) | Screenshots smart con snap a ventanas | ✅ |
| [`webapps/`](webapps/README.md) | Web apps como launchers nativos | ✅ |
| [`clipboard/`](clipboard/README.md) | Historial de clipboard con modo delete | ✅ |
| [`screen-recording/`](screen-recording/README.md) | Grabación toggle con pausa/resume | ✅ |
| [`ocr/`](ocr/README.md) | OCR de región a clipboard | ✅ |
| [`reminders/`](reminders/README.md) | Recordatorios via systemd user timers | ✅ |
| [`launch-or-focus/`](launch-or-focus/README.md) | Lanzar o enfocar app existente | ✅ |
| [`workspace-groups/`](workspace-groups/README.md) | Workspaces en grupos de 10 | ✅ |
| [`xcompose/`](xcompose/README.md) | Emojis y em dash con XCompose | ✅ |
| [`hardware/`](hardware/README.md) | GPU/CPU config, batería, brillo | ✅ |
| [`wiremix/`](wiremix/wiremix.toml) | Mixer de audio TUI (PipeWire) | ✅ |
| [`material-you/`](material-you/README.md) | Theming dinámico con matugen | 🔧 pendiente |
| [`quickshell/`](quickshell/README.md) | Shell bar Qt6/QML | 🔧 pendiente |

---

## Referencias de dotfiles

Ver [`references/`](references/README.md) — dotfiles explorados como referencia para construir los propios.

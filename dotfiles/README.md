# dotfiles

Arch Linux — Hyprland — Quickshell — Neovim

Deployed with [GNU Stow](https://www.gnu.org/software/stow/).

---

## Deploy

```bash
# Todo de una
./deploy.sh

# Paquetes específicos
./deploy.sh nvim zsh

# Simular sin hacer cambios
./deploy.sh --dry-run
```

## Estructura

Cada directorio es un paquete de Stow. La estructura interna replica el path relativo
a `$HOME`. Por ejemplo:

```
nvim/.config/nvim/  →  ~/.config/nvim/
zsh/.zshrc          →  ~/.zshrc
scripts/.local/bin/ →  ~/.local/bin/
```

## Paquetes

| Paquete | Destino | Estado |
|---|---|---|
| `nvim` | `~/.config/nvim/` | pendiente de poblar |
| `yazi` | `~/.config/yazi/` | pendiente de poblar |
| `zsh` | `~/` | pendiente de poblar |
| `kitty` | `~/.config/kitty/` | pendiente de poblar |
| `btop` | `~/.config/btop/` | pendiente de poblar |
| `fastfetch` | `~/.config/fastfetch/` | pendiente de poblar |
| `starship` | `~/.config/` | pendiente de poblar |
| `mpd` | `~/.config/mpd/` | pendiente de poblar |
| `ncmpcpp` | `~/.config/ncmpcpp/` | pendiente de poblar |
| `zellij` | `~/.config/zellij/` | pendiente de poblar |
| `wiremix` | `~/.config/wiremix/` | pendiente de poblar |
| `spicetify` | `~/.config/spicetify/` | pendiente de poblar |
| `git` | `~/` | pendiente de poblar |
| `systemd` | `~/.config/systemd/user/` | pendiente de poblar |
| `scripts` | `~/.local/bin/` | pendiente de poblar |
| `hypr` | `~/.config/hypr/` | 🔧 WIP — propio en construcción |
| `quickshell` | `~/.config/quickshell/` | 🔧 WIP — en construcción |

## Referencias

Ver `~/Files/Configuraciones/references/` para:
- Patterns de Caelestia shell (Quickshell/QML)
- Patterns de ii/end-4 (Quickshell/QML)
- Pipeline de matugen
- Estrategia de deploy completa

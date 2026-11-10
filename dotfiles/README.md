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

| Paquete | Destino |
|---|---|
| `btop` | `~/.config/btop/` |
| `fastfetch` | `~/.config/fastfetch/` |
| `fonts` | `~/.local/share/fonts/` |
| `git` | `~/.gitconfig` |
| `hypr` | `~/.config/hypr/` |
| `kitty` | `~/.config/kitty/` |
| `matugen` | `~/.config/matugen/`, `~/.config/systemd/user/matugen-server.service` |
| `mimeapps` | `~/.config/mimeapps.list` |
| `mpd` | `~/.config/mpd/` |
| `mpv` | `~/.config/mpv/` |
| `ncmpcpp` | `~/.config/ncmpcpp/` |
| `nvim` | `~/.config/nvim/` |
| `quickshell` | `~/.config/quickshell/` |
| `scripts` | `~/.local/bin/`, `~/.local/share/webapps/` — ver `scripts/README.md` |
| `starship` | `~/.config/starship.toml` |
| `systemd` | `~/.config/systemd/user/` |
| `termfilechooser` | `~/.config/xdg-desktop-portal-termfilechooser/` |
| `uwsm` | `~/.config/uwsm/` — PATH fix for `~/.local/bin` in the graphical session, see `scripts/README.md` |
| `vesktop` | `~/.config/vesktop/` |
| `wiremix` | `~/.config/wiremix/` |
| `xdg-portal` | `~/.config/xdg-desktop-portal/` |
| `yazi` | `~/.config/yazi/` |
| `zsh` | `~/.zshrc`, `~/.zshenv`, `~/.p10k.zsh` |

**No deployados por Stow** (`PENDING` en `deploy.sh`):

| Paquete | Por qué |
|---|---|
| `stylus` | Userstyles para la extensión Stylus — se importan a mano en el navegador, no se symlinkean |
| `chromium-extension` | Se carga directo desde el path del repo vía "Load unpacked" de Chrome (ver `backup/references/post-install.md`) |

## Referencias

Ver `backup/references/README.md` para:
- Patterns de Caelestia shell y de ii/end-4 (Quickshell/QML)
- Pipeline de matugen
- Estrategia de deploy con Stow
- Configuración manual post-bootstrap

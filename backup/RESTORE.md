# Guía de Restauración

> Ejecutar esto cuando sea el momento de migrar a un sistema nuevo o construir los propios dotfiles.
> Orden de fases importa — identidad primero, herramientas después.

Sistema origen: Arch Linux + Hyprland + Caelestia shell → migración a Omarchy

---

## Fase 1 — Identidad y acceso

### SSH

```bash
mkdir -p ~/.ssh
cp ~/Files/Configuraciones/ssh/id_ed25519     ~/.ssh/
cp ~/Files/Configuraciones/ssh/id_ed25519.pub ~/.ssh/
cp ~/Files/Configuraciones/ssh/known_hosts    ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
ssh -T git@github.com    # verificar: debe responder con el usuario correcto
```

### Git

```bash
cp ~/Files/Configuraciones/git/.gitconfig ~/.gitconfig
# Limpiar entradas safe.directory que ya no apliquen
```

### GitHub CLI

```bash
mkdir -p ~/.config/gh
cp ~/Files/Configuraciones/gh/config.yml ~/.config/gh/
cp ~/Files/Configuraciones/gh/hosts.yml  ~/.config/gh/
gh auth status    # si el token expiró: gh auth login
```

### GPG

```bash
gpg --import ~/Files/Configuraciones/gnupg/public-keys.asc
gpg --import-ownertrust ~/Files/Configuraciones/gnupg/trustdb.txt
```

---

## Fase 2 — Shell (zsh)

> **Nota Omarchy:** Omarchy instala su propio zsh. Integrar funciones en lugar de
> reemplazar el `.zshrc` completo.

```bash
ln -sf ~/Files/Configuraciones/zsh ~/.config/zsh
```

Agregar al final del `.zshrc` de Omarchy:

```bash
source "$HOME/.config/zsh/terminal.zsh"
source "$HOME/.config/zsh/prompt.zsh"
source "$HOME/.config/zsh/user.zsh"
export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:/home/$USER/.spicetify
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

Plugins (cargados por Zinit): `zsh-autosuggestions`, `zsh-syntax-highlighting`,
`zsh-completions`, `zsh-256color`.

Dependencias de aliases: `eza` (ls/ll), `nvim` (n), `ncmpcpp` (music),
`yay` o `paru` en variable `$aurhelper`.

---

## Fase 3 — Neovim

```bash
ln -sf ~/Files/Configuraciones/nvim ~/.config/nvim
# Abrir nvim → Lazy.nvim descarga todos los plugins automáticamente
# Ver nvim/CLAUDE.md para documentación completa
```

---

## Fase 4 — Zen Browser

Instalar Zen Browser y ejecutarlo al menos una vez, luego:

```bash
ZEN_PROFILE="$HOME/.config/zen/TU_PERFIL_ACTIVO"   # ls ~/.config/zen/ para ver cuál es
cp -r ~/Files/Configuraciones/zen/profile/chrome/         "$ZEN_PROFILE/"
cp    ~/Files/Configuraciones/zen/profile/places.sqlite    "$ZEN_PROFILE/"
cp    ~/Files/Configuraciones/zen/profile/prefs.js         "$ZEN_PROFILE/"
cp    ~/Files/Configuraciones/zen/profile/extensions.json  "$ZEN_PROFILE/"
cp    ~/Files/Configuraciones/zen/profile/containers.json  "$ZEN_PROFILE/"
cp -r ~/Files/Configuraciones/zen/profile/bookmarkbackups/ "$ZEN_PROFILE/"
# Zen debe estar cerrado. Reiniciar después.
# Las extensiones del extensions.json se re-descargan solas al abrir.
```

---

## Fase 5 — Vesktop (Discord)

```bash
mkdir -p ~/.config/vesktop/settings
cp -r ~/Files/Configuraciones/vesktop/settings/. ~/.config/vesktop/settings/
cp    ~/Files/Configuraciones/vesktop/settings.json ~/.config/vesktop/
# Si no se usa Caelestia: cambiar tema en Vencord Settings → Themes
```

---

## Fase 6 — Spicetify

```bash
yay -S spicetify-cli
cp -r ~/Files/Configuraciones/spicetify/. ~/.config/spicetify/
# Editar config-xpui.ini → actualizar spotify_path y prefs_path
# Con spotify-launcher:
#   spotify_path = /home/$USER/.local/share/spotify-launcher/install/usr/share/spotify
#   prefs_path   = /home/$USER/.config/spotify/prefs
spicetify backup apply
```

---

## Fase 7 — Yazi

```bash
ln -sf ~/Files/Configuraciones/yazi ~/.config/yazi
ya pack -i    # instala plugins
# Ver yazi/README.md para lista completa de plugins y keymaps
```

---

## Fase 8 — MPD + ncmpcpp

```bash
ln -sf ~/Files/Configuraciones/mpd    ~/.config/mpd
ln -sf ~/Files/Configuraciones/ncmpcpp ~/.config/ncmpcpp
systemctl --user enable --now mpd
```

---

## Fase 9 — Starship

```bash
ln -sf ~/Files/Configuraciones/starship ~/.config/starship
# Nota Omarchy: verificar si ya usa Starship antes de hacer el symlink.
# Si usa otro prompt, agregar manualmente al .zshrc:
#   eval "$(starship init zsh)"
#   export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
```

---

## Fase 10 — Fastfetch

```bash
ln -sf ~/Files/Configuraciones/fastfetch ~/.config/fastfetch
# Si en Omarchy los logos no se renderizan:
# Cambiar en fastfetch/config.jsonc: "type": "kitty" → "type": "auto"
```

---

## Fase 11 — Fuentes

```bash
cp -r ~/Files/Configuraciones/fonts/. ~/.fonts/
fc-cache -fv
yay -S ttf-iosevka-term-nerd    # fuente del terminal
```

---

## Fase 12 — Apps por defecto

```bash
cp ~/Files/Configuraciones/mimeapps.list ~/.config/mimeapps.list
cp -r ~/Files/Configuraciones/applications/. ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
# mimeapps.list apunta a Zen Browser y Yazi — ajustar si los nombres cambian
```

---

## Fase 13 — Obsidian

Los vaults viven en `Files/Documents/` — viajan con los archivos, no están aquí.
Lo que está aquí es solo el registro de vaults:

```bash
mkdir -p ~/.config/obsidian
cp ~/Files/Configuraciones/obsidian/obsidian.json ~/.config/obsidian/
# Si Documents/ quedó en otra ruta: editar obsidian.json → actualizar campos "path"
```

Vaults al momento del backup:
- `UNIVERSIDAD` → `~/Files/Documents/UNIVERSIDAD`
- `Junior Cybersecurity Analyst (HackTheBox)` → `~/Files/Documents/CERTIFICADOS Y OTROS/...`

El tema Caelestia no existe en Omarchy. Opciones: mantener el snapshot CSS como tema
estático, o cambiar de tema en Appearance → Themes.

---

## Fase 14 — Kitty (opcional en Omarchy)

> Omarchy usa Ghostty como terminal. Kitty es secundario.

```bash
ln -sf ~/Files/Configuraciones/kitty ~/.config/kitty
# Ver kitty/SETUP.md para documentación del sistema de temas
```

---

## Variables de entorno

Definidas en `zsh/user.zsh` — verificar que sigan siendo válidas en sistema nuevo:

```bash
export GEMINI_API_KEY="..."
export SUDO_EDITOR="nvim ..."
export EDITOR="nvim"
export MANPAGER='nvim +Man!'
export LIBVIRT_DEFAULT_URI="qemu:///system"
export PATH=$PATH:/home/$USER/.spicetify
```

---

## Apps que NO necesitan restauración

| App | Motivo |
|---|---|
| WinApps | Requiere setup nuevo de KVM/libvirt de todas formas |
| OBS Studio | Config de escenas se rehace rápido |
| KDE Connect | Re-parear dispositivos es trivial |
| Zed / OpenCode | Config minimal, se regenera |
| w3m | Config básica sin personalización significativa |

---

## Checklist de verificación post-instalación

- [ ] `ssh -T git@github.com` responde con el usuario correcto
- [ ] `gh auth status` muestra autenticado
- [ ] `git config user.email` devuelve `yannelmorales51@gmail.com`
- [ ] `nvim` abre y Lazy.nvim carga sin errores
- [ ] Zen Browser abre con marcadores y tema `chrome/` aplicado
- [ ] Vesktop abre con plugins Vencord activos
- [ ] `music` (ncmpcpp) conecta a MPD y ve la librería
- [ ] Spicetify aplica tema en Spotify
- [ ] `fastfetch` muestra logo y sistema correctamente
- [ ] Aliases de zsh (`ls`, `ll`, `n`, `up`) funcionan
- [ ] Obsidian abre los vaults y muestra las notas
- [ ] `webapp-launch https://youtube.com/` abre en modo app
- [ ] `screenshot` abre selector y guarda captura
- [ ] `ocr` — seleccionás región, texto queda en clipboard
- [ ] `reminder 5 "test"` llega notificación en 5 min
- [ ] `clipboard` abre historial; `clipboard --delete` elimina entradas
- [ ] `record` inicia grabación; segundo `record` la detiene
- [ ] `wiremix` abre mixer de audio

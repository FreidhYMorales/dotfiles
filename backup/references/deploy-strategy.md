# Deploy Strategy — Dotfiles

**Decisión:** GNU Stow  
**Fecha:** 2026-06-04  
**Alcance:** una sola máquina

---

## Por qué Stow (y no chezmoi)

| | Stow | chezmoi |
|---|---|---|
| Complejidad | Mínima | Media-alta |
| Mecanismo | Symlinks | Copia + templates |
| Templating por-machine | No | Sí |
| Deps | Solo `stow` | binario chezmoi |
| Depuración | `ls -la ~` | `chezmoi diff` |

chezmoi brillaría si hubiera múltiples máquinas con variaciones (laptop + server + VM).
Para una sola máquina, Stow es suficiente y más transparente.

---

## Cómo funciona Stow

```
dotfiles/
└── nvim/
    └── .config/
        └── nvim/        ← carpeta real con los archivos

stow -t ~ nvim
→ crea: ~/.config/nvim → /home/deadlock/Files/dotfiles/nvim/.config/nvim
```

La regla es simple: **la estructura dentro del paquete replica el path desde `$HOME`**.

```
dotfiles/zsh/.zshrc         →  ~/.zshrc
dotfiles/git/.gitconfig     →  ~/.gitconfig
dotfiles/scripts/.local/bin/screenshot  →  ~/.local/bin/screenshot
```

---

## Repo

Ubicación: `~/Files/dotfiles/`  
Deploy: `./deploy.sh` (corre `stow -v --target=$HOME <pkg>` por cada paquete)

```bash
./deploy.sh              # todo
./deploy.sh nvim zsh     # paquetes específicos
./deploy.sh --dry-run    # simular sin cambios
```

Para deshacer: `stow -D --target=$HOME nvim`

---

## Paquetes y estado

| Paquete | Qué cubre | Estado |
|---|---|---|
| `nvim` | `~/.config/nvim/` | pendiente de poblar |
| `yazi` | `~/.config/yazi/` | pendiente de poblar |
| `zsh` | `.zshrc`, `.zshenv`, `functions/` | pendiente de poblar |
| `kitty` | `~/.config/kitty/` | pendiente de poblar |
| `btop` | `~/.config/btop/` | pendiente de poblar |
| `fastfetch` | `~/.config/fastfetch/` | pendiente de poblar |
| `starship` | `~/.config/starship.toml` | pendiente de poblar |
| `mpd` | `~/.config/mpd/` | pendiente de poblar |
| `ncmpcpp` | `~/.config/ncmpcpp/` | pendiente de poblar |
| `zellij` | `~/.config/zellij/` | pendiente de poblar |
| `wiremix` | `~/.config/wiremix/` | pendiente de poblar |
| `spicetify` | `~/.config/spicetify/` | pendiente de poblar |
| `git` | `.gitconfig`, `.gitignore_global` | pendiente de poblar |
| `systemd` | `~/.config/systemd/user/` | pendiente de poblar |
| `scripts` | `~/.local/bin/` — todos los feature scripts | pendiente de poblar |
| `hypr` | `~/.config/hypr/` | 🔧 WIP — propio en construcción |
| `quickshell` | `~/.config/quickshell/` | 🔧 WIP — en construcción |

---

## Flujo para agregar un config nuevo

```bash
# 1. Crear el paquete si no existe
mkdir -p ~/Files/dotfiles/foo/.config/foo

# 2. Copiar la config actual
cp -r ~/.config/foo/* ~/Files/dotfiles/foo/.config/foo/

# 3. Borrar el original y hacer stow
rm -rf ~/.config/foo
cd ~/Files/dotfiles && stow -v --target=$HOME foo

# 4. Verificar
ls -la ~/.config/foo   # debe ser un symlink
```

---

## Próximos pasos

1. Poblar los paquetes desde los backups en `~/Files/Configuraciones/`
2. Correr `./deploy.sh --dry-run` para verificar conflictos antes del deploy real
3. Resolver conflictos (archivos que ya existen en `~/.config/` como archivos reales, no symlinks)
4. Correr `./deploy.sh` definitivo
5. Crear repo en GitHub (privado) y pushear

---

## Nota sobre configs sensibles

`~/Files/Configuraciones/backups/` tiene: gnupg/, ssh/, gh/.  
Están en `.gitignore` de Configuraciones y NO deben entrar al repo de dotfiles.  
Se restauran manualmente desde el backup — ver RESTORE.md.

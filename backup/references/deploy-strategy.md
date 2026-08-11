# Deploy Strategy — Dotfiles

**Decisión:** GNU Stow
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
→ crea: ~/.config/nvim → <repo>/dotfiles/nvim/.config/nvim
```

La regla es simple: **la estructura dentro del paquete replica el path desde `$HOME`**.

```
dotfiles/zsh/.zshrc         →  ~/.zshrc
dotfiles/git/.gitconfig     →  ~/.gitconfig
dotfiles/scripts/.local/bin/screenshot  →  ~/.local/bin/screenshot
```

Ver `dotfiles/README.md` para la lista de paquetes actuales y `dotfiles/deploy.sh` para el flujo de deploy real.

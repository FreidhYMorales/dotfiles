# QUICK_REFERENCE — Estado actual de la config

**Última actualización:** 2026-05-11
**Yazi:** 26.5.6
**Config root:** `/home/deadlock/Files/Configuraciones/yazi/`
**Activar config:** `YAZI_CONFIG_HOME=<config_root> yazi`

---

## Estado de archivos principales

| Archivo       | Estado     | Notas                                              |
|---------------|------------|----------------------------------------------------|
| `yazi.toml`   | ✅ Base    | ratio 1:3:4, Kitty image proto, openers nvim+xdg; previewers usan `url=` (26.x) |
| `theme.toml`  | ✅ Base    | Flavor "deadlock" (dark+light), highlight cuadrado |
| `keymap.toml` | ✅ Base    | Vim nav + sorting + tabs; secciones por plugin     |
| `init.lua`    | ✅ Base    | full-border PLAIN + 15 plugins configurados        |
| `package.toml`| ✅ Base    | 15 plugins + 2 flavors registrados                 |

---

## Tabla de Keybinds activos

### Manager

| Tecla(s)      | Acción                         | Fuente    |
|---------------|--------------------------------|-----------|
| `h`           | leave (ir a padre)             | keymap    |
| `l` / `→` / `Enter` | bypass smart-enter        | bypass    |
| `H`           | back (historial)               | keymap    |
| `L`           | forward (historial)            | keymap    |
| `j` / `k`     | cursor down / up               | default   |
| `g,g`         | cursor top                     | default   |
| `G`           | cursor bottom                  | default   |
| `<C-d>`       | cursor page down               | default   |
| `<C-u>`       | cursor page up                 | default   |
| `s,n`         | sort natural                   | keymap    |
| `s,a`         | sort alphabetical               | keymap    |
| `s,m`         | sort modified (newest)         | keymap    |
| `s,s`         | sort size (largest)            | keymap    |
| `T`           | tab_create --current           | keymap    |
| `X`           | tab_close 0                    | keymap    |
| `<Tab>`       | tab_switch +1                  | keymap    |
| `<S-Tab>`     | tab_switch -1                  | keymap    |
| `.`           | hidden toggle                  | keymap    |
| `!`           | shell --block --confirm        | keymap    |
| `Space`       | select (toggle)                | default   |
| `y`           | yank (copy)                    | default   |
| `x`           | yank --cut                     | default   |
| `p`           | paste                          | default   |
| `d`           | remove (trash)                 | default   |
| `a`           | create (new file/dir)          | default   |
| `r`           | rename                         | default   |
| `f`           | filter                         | default   |
| `/`           | find (incremental)             | default   |
| `z`           | jump (zoxide/fzf)              | default   |
| `~`           | help                           | default   |

### Input

| Tecla    | Acción             |
|----------|--------------------|
| `<C-c>`  | close (cancel)     |
| `<Esc>`  | escape             |
| `<C-u>`  | kill to start      |
| `<C-k>`  | kill to end        |

---

## Stack de plugins — Progreso (orden de instalación)

| #  | Plugin           | Categoría  | Instalado | Configurado | Keybind      | Estado              |
|----|------------------|------------|-----------|-------------|--------------|---------------------|
| 01 | yatline          | UI         | ✅        | ✅          | automático   | ✅ OK               |
| 02 | clipboard        | Core       | ✅        | ✅          | `y` / `<C-p>`| ✅ OK               |
| 03 | relative-motions | Workflow   | ✅        | ✅          | `1`–`9`      | ✅ OK               |
| 04 | bypass           | Workflow   | ✅        | ✅          | `l`/`→`/`Enter` | ✅ OK            |
| 05 | fg               | Search     | ✅        | ✅          | `f,g/G/f`    | ✅ OK               |
| 06 | gvfs             | System     | ✅        | ✅          | `M,*` / `g,m`| ✅ OK               |
| 07 | mount            | System     | ✅        | ✅          | `M,M`        | ✅ OK               |
| 08 | rich-preview     | Preview    | ✅        | ✅          | automático   | ✅ OK               |
| —  | piper            | Preview    | ✅        | ✅          | automático   | ✅ OK (wrapper)     |
| 09 | glow (via piper) | Preview    | ✅        | ✅          | automático   | ✅ OK               |
| 10 | hexyl (via piper)| Preview    | ✅        | ✅          | automático   | ⏸ Deshabilitado (append_previewers comentado) |
| 11 | mediainfo        | Preview    | ✅        | ✅          | `I` toggle   | ✅ OK               |
| 12 | ouch             | Archiving  | ✅        | ✅          | `C`          | ✅ OK               |
| 13 | what-size        | Utility    | ✅        | ✅          | `<C-s>`      | ✅ OK               |
| 14 | lazygit          | Git        | ✅        | ✅          | `g,i`        | ✅ OK               |
| 15 | recycle-bin      | Security   | ✅        | ✅          | `R,b`+más    | ✅ OK               |
| 16 | piper            | Automation | ✅        | ✅          | automático   | ✅ OK (wrapper)     |
| 00 | full-border      | UI         | ✅        | ✅          | —            | ✅ OK (PLAIN)       |
| —  | ~~starship~~     | ~~UI~~     | —         | —           | —            | ❌ Eliminado        |

---

## Gaps conocidos

- Ninguno — stack completo ✅

# Módulo 1 — Arquitectura (Core)

---

## 1.1 Estructura de Carpetas

```
/home/deadlock/Files/Configuraciones/yazi/   ← YAZI_CONFIG_HOME
│
├── yazi.toml          # Manager, openers, previewers, tasks
├── keymap.toml        # Keybinds ([mgr], [input], [select])
├── theme.toml         # Colores ANSI puros
├── init.lua           # Setup de plugins, orden de carga
│
├── plugins/           # SYMLINK → ~/.config/yazi/plugins/
│   │                  # (ya pkg add instala aquí; el symlink lo expone)
│   ├── yatline.yazi/
│   ├── clipboard.yazi/
│   ├── relative-motions.yazi/
│   ├── bypass.yazi/
│   ├── fg.yazi/
│   ├── gvfs.yazi/
│   ├── mount.yazi/
│   ├── rich-preview.yazi/
│   ├── piper.yazi/
│   ├── mediainfo.yazi/
│   ├── ouch.yazi/
│   ├── what-size.yazi/
│   ├── lazygit.yazi/
│   └── recycle-bin.yazi/
│
├── CONTEXT/           # Referencia interna — no afecta a Yazi
│   ├── INVARIANTS.md
│   ├── QUICK_REFERENCE.md
│   └── PLUGIN_REGISTRY.md
│
├── docs/              # Esta documentación
│   ├── 01_ARCHITECTURE.md
│   ├── 02_UI.md
│   ├── 03_KEYMAPS.md
│   ├── 04_ECOSYSTEM.md
│   └── 05_TROUBLESHOOTING.md
│
└── README.md          # Índice de entrada
```

**Por qué `plugins/` es un symlink:**
`ya pkg add` instala siempre en `~/.config/yazi/plugins/`. Yazi con `YAZI_CONFIG_HOME` busca plugins en `$YAZI_CONFIG_HOME/plugins/`. Sin el symlink, los keybinds `plugin <name>` fallan silenciosamente.

```bash
# Crear symlink (solo una vez por sistema)
ln -s ~/.config/yazi/plugins /home/deadlock/Files/Configuraciones/yazi/plugins
```

---

## 1.2 Flujo de Datos

### Selección y Preview de archivos

```
Usuario navega a un archivo
        │
        ▼
  Yazi identifica MIME type (libmagic)
        │
        ▼
  prepend_preloaders   ← se ejecutan primero (gvfs noop, mediainfo)
        │
        ▼
  prepend_previewers   ← orden de prioridad:
  │  1. noop (gvfs/mtp mount points)
  │  2. mediainfo  → audio/*, video/*, image/*
  │  3. glow       → *.md  (via piper)
  │  4. rich-preview → *.csv, *.rst, *.ipynb
  │  5. ouch       → archives (zip, tar, rar...)
        │
        ▼
  Built-in previewers  ← Yazi defaults (imágenes via Kitty, texto, código)
        │
        ▼
  append_previewers    ← actualmente deshabilitado (comentado en yazi.toml)
     (hexyl via piper — hex dump; descomentar si se necesita fallback binario)
```

### Apertura de archivos (Enter / l)

```
Usuario pulsa Enter/l sobre un archivo
        │
        ▼
  bypass plugin: ¿es directorio de hijo único?
  ├── Sí → entrar directamente (smart-enter)
  └── No → evaluar [open].rules en yazi.toml
              │
              ▼
        Primer mime que coincide:
        ├── archives    → ouch decompress "$@"  (block=true)
        ├── text/*      → nvim "$@"  (block=true)
        ├── image/*     → xdg-open
        ├── video/*     → xdg-open
        ├── audio/*     → xdg-open
        ├── pdf         → xdg-open
        └── *           → nvim o xdg-open
```

### Invocación de plugins via keybind

```
Usuario pulsa keybind (ej: f,g)
        │
        ▼
  Yazi busca en $YAZI_CONFIG_HOME/plugins/fg.yazi/
        │           (requiere symlink plugins/)
        ▼
  Ejecuta main.lua del plugin
        │
        ▼
  Plugin puede:
  ├── Mostrar UI propia (fg, gvfs, mount, recycle-bin)
  ├── Lanzar proceso externo bloqueante (lazygit, shell)
  └── Modificar estado de Yazi (clipboard, relative-motions)
```

---

## 1.3 Independencia de Neovim — Justificación Técnica

**Principio:** Yazi es un file manager CLI. Neovim es un editor. Son herramientas ortogonales.

### Regla (Invariante I-04)

Ningún plugin de Yazi invoca Neovim directamente. Neovim solo entra en escena como **opener** cuando el usuario abre explícitamente un archivo.

```toml
# yazi.toml — Neovim como opener, nunca como dependencia de plugin
[opener]
edit = [
  { run = 'nvim "$@"', block = true, desc = "Neovim" },
]
```

### Por qué esta separación

| Sin separación | Con separación |
|----------------|----------------|
| Plugin `fg` abre nvim → Yazi queda bloqueado | `fg` navega en Yazi → usuario decide si abrir |
| Config de Yazi depende del estado de nvim | Yazi funciona sin nvim instalado |
| Debugging mezclado entre dos herramientas | Cada herramienta se depura de forma independiente |
| Si nvim crashea, Yazi crashea | Yazi siempre estable |

### Caso concreto — fg plugin

```lua
-- INCORRECTO: fg invoca nvim → viola separación
require("fg"):setup({ default_action = "nvim" })

-- CORRECTO: fg navega en Yazi → el usuario controla qué hacer después
require("fg"):setup({ default_action = "jump" })
```

### Integración legítima Yazi ↔ Neovim

La integración correcta es **Neovim → Yazi** (no al revés), via el plugin `oil.nvim` u otros que lancen Yazi como proceso hijo desde dentro de Neovim. En esa dirección, Neovim controla el ciclo de vida y no hay acoplamiento de dependencias.

---

## 1.4 Activación de la Config

```bash
# Uso puntual
YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi

# Función en ~/.zshrc (preserva cwd-changer)
function y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi \
    yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
```

La función `y()` es preferible al alias porque preserva el comportamiento de `--cwd-file`, que permite que el shell cambie al directorio donde Yazi terminó.

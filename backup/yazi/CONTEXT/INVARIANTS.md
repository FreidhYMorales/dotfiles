# INVARIANTS — Reglas duras que NO deben romperse

Estas reglas son el resultado de bugs ya resueltos o decisiones de diseño firmes.
Verificar contra esta lista antes de proponer cualquier cambio.

---

## I-00 — Sección de keymap: [mgr] no [manager]

**Regla:** En `keymap.toml`, el contexto del file manager se declara como `[mgr]`, no `[manager]`.

```toml
[mgr]              ← CORRECTO en Yazi 26.x
prepend_keymap = [...]

[manager]          ← INCORRECTO — sección ignorada silenciosamente
prepend_keymap = [...]
```

**Por qué:** En Yazi 26.x el nombre interno cambió de `manager` a `mgr`. Una sección `[manager]` se parsea sin error pero sus keybinds nunca se cargan. `[input]` y `[select]` no cambiaron.

**Síntoma:** Keybinds custom no responden; plugins invocados via keybind no hacen nada.

---

## I-00b — Sintaxis de args en plugin keybinds

**Regla:** Para pasar argumentos a un plugin via keybind, usar espacio directo — sin `--args=`.

```toml
run = "plugin relative-motions 1"        ← CORRECTO
run = "plugin relative-motions --args=1" ← INCORRECTO en Yazi 26.x
run = "plugin clipboard -- --action=copy" ← CORRECTO (doble guion para flags propias del plugin)
```

---

## I-00c — Symlink obligatorio: plugins/ → ~/.config/yazi/plugins/

**Regla:** `/home/deadlock/Files/Configuraciones/yazi/plugins` DEBE ser un symlink a `~/.config/yazi/plugins`.

```bash
ln -s ~/.config/yazi/plugins /home/deadlock/Files/Configuraciones/yazi/plugins
```

**Por qué:** `ya pkg add` instala siempre en `~/.config/yazi/plugins/`. Yazi con `YAZI_CONFIG_HOME` busca plugins en `$YAZI_CONFIG_HOME/plugins/`. Sin el symlink, los plugins invocados via keybind (`plugin <name>`) no cargan — sin error, sin notificación. Los plugins cargados via `require()` en init.lua sí funcionan (Lua busca en otra ruta), lo que enmascara el problema.

**Síntoma de ruptura:** `plugin <name>` en keybind no hace nada, sin notificación.

---

## I-01 — Theme basado en flavor "deadlock"

**Estado actual:** `theme.toml` usa estructura de flavor.

```toml
[flavor]
dark  = "deadlock"
light = "deadlock"
```

**Regla:** Cualquier cambio de color va en el flavor file, no en `theme.toml` directamente. El flavor "deadlock" es el sistema de colores canónico.

**Nota histórica:** La config original usaba ANSI puro (`use = ""`). Se migró a flavor para tener un highlight de selección con esquinas cuadradas (el highlight redondeado fue corregido vía el flavor). El invariante de "nunca hex" puede o no aplicar dentro del flavor — depende de cómo esté definido.

**I-02 sigue vigente:** Los colores en Lua (init.lua/yatline) siguen usando la convención sin guion (`"brightblack"`).

---

## I-02 — Nombres de color en Lua ≠ en theme.toml

**Regla:** En `init.lua` los colores bright NO llevan guion. En `theme.toml` SÍ.

| Contexto | Correcto | Incorrecto |
|---|---|---|
| `theme.toml` | `"bright-black"` | `"brightblack"` |
| `init.lua` (Lua) | `"brightblack"` | `"bright-black"` |

**Por qué:** Son APIs distintas — el parser TOML de Yazi y la API Lua de Yazi usan convenciones diferentes para los mismos colores.

---

## ~~I-02-original~~ — ELIMINADO

starship retirado del stack. yatline gestiona header + status completos.
`header_line` ahora tiene contenido: tabs (izq) + hora (der).

---

## I-03 — Verificar tipo de retorno antes de llamar :setup()

**Regla:** Leer la última línea (`return`) del `main.lua` de cada plugin antes de añadir `:setup()` en init.lua.

**Tabla de decisión:**
```
return { entry = ... }   → tabla plana → NO tiene :setup() → solo require("plugin")
return M  (con M:setup() definido) → SÍ tiene :setup() → require("plugin"):setup({ ... })
```

**Plugins sin setup() — solo `require(...)`:**
- bypass, system-clipboard, lazygit, glow, hexyl, mediainfo, mount, ouch, piper, rich-preview

**Plugins con setup():**
- relative-motions, recycle-bin, gvfs, what-size, fg, yatline

**Nunca hacer:**
```lua
require("bypass"):setup()        -- ← crash en runtime
require("system-clipboard"):setup()  -- ← crash en runtime
```

---

## I-04 — Yazi es CLI puro — sin integración Neovim desde plugins

**Regla:** Ningún plugin debe delegar acciones a Neovim directamente.

**Por qué:** Neovim y Yazi son herramientas independientes. Yazi abre archivos con su opener (`nvim` en el opener `edit`), pero los plugins no deben invocar nvim internamente.

**Caso concreto — fg plugin:**
```lua
-- INCORRECTO:
require("fg"):setup({ default_action = "nvim" })

-- CORRECTO:
require("fg"):setup({ default_action = "jump" })  -- navega en Yazi
```

El opener `edit` (nvim) sigue disponible manualmente con `Enter`/`l`.

---

## I-05 — Filetype rules: `is =` requiere acompañante `url` o `mime`

**Regla:** En `[filetype]` rules, `is =` nunca puede ser el único campo selector. Siempre debe ir acompañado de `url` o `mime`.

**Por qué:** En Yazi 26.x, la validación requiere al menos uno de `url` o `mime`. Un entry con solo `is =` genera "at least one of `url` or `mime` must be specified" y Yazi no arranca.

```toml
# INCORRECTO — is solo, sin url ni mime
{ is = "link",   style = { fg = "cyan" } }
{ is = "dir",    style = { fg = "blue" } }   ← además, "dir" no es valor válido de is

# CORRECTO — is acompañado de url
{ url = "**/*", is = "link",   style = { fg = "cyan"                  } }
{ url = "**/*", is = "orphan", style = { fg = "red",  underline = true } }
{ url = "**/*", is = "exec",   style = { fg = "green", bold = true     } }

# CORRECTO — directorios via mime (is = "dir" no existe)
{ mime = "inode/directory", style = { fg = "blue", bold = true } }
```

**Valores válidos de `is`:** `hidden`, `link`, `orphan`, `dummy`, `block`, `char`, `fifo`, `sock`, `exec`, `sticky`.

---

## I-06 — Config activada con variable de entorno

**Regla:** Esta config NO está en `~/.config/yazi/`. Se activa así:

```bash
YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi
```

Para que sea permanente, añadir en `~/.zshrc`:
```zsh
alias yazi='YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi'
# o con una función que preserve el cwd-changer de Yazi:
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

---

## I-07 — prepend_keymap, no append_keymap

**Regla:** Usar siempre `prepend_keymap` en keymap.toml para sobreescribir defaults.

**Por qué:** `prepend_keymap` tiene prioridad sobre los defaults internos de Yazi. `append_keymap` se evalúa después y puede ser anulado por un default con la misma tecla.

---

## I-08 — Yazi 26.x: `name =` → `url =` en preloaders/previewers

**Regla:** En las secciones `prepend_preloaders`, `prepend_previewers` y `append_previewers` de `yazi.toml`, el campo para glob de rutas/nombres es `url`, no `name`.

```toml
# INCORRECTO (Yazi <26.x)
{ name = "*.md",             run = "piper -- glow ..." }
{ name = "/run/media/**/*",  run = "noop" }

# CORRECTO (Yazi 26.x)
{ url = "*.md",              run = "piper -- glow ..." }
{ url = "/run/media/**/*",   run = "noop" }
```

**Síntoma:** "TOML parse error … missing comma between array elements" (el campo `name` desconocido rompe el array).

---

## I-09 — Yazi 26.x: `tab_width` eliminado de `[manager]` en flavor

**Regla:** El campo `tab_width` ya no es válido en la sección `[manager]` de un flavor file.

```toml
# INCORRECTO — genera "data did not match any variant of untagged enum CustomField"
[manager]
tab_width = 1

# CORRECTO — eliminar la línea; el ancho de tab se controla en yatline via init.lua
```

**Síntoma:** "data did not match any variant of untagged enum CustomField" al arrancar.

---

## Anti-patrones conocidos

| Anti-patrón                              | Consecuencia                                  |
|------------------------------------------|-----------------------------------------------|
| `[manager]` en keymap.toml              | Sección ignorada, keybinds no cargan          |
| `plugin name --args=val` en keybind     | Plugin no recibe args, se comporta mal        |
| `is = "..."` solo en filetype rules     | Yazi no arranca (falta url o mime)            |
| `is = "dir"` en filetype rules          | Yazi no arranca ("dir" no es valor válido)    |
| `name =` en previewers/preloaders       | Yazi no arranca (renombrado a `url =`)        |
| `tab_width = 1` en flavor [manager]     | Yazi no arranca (campo eliminado en 26.x)     |
| `require("bypass"):setup()`             | Runtime crash                                 |
| `fg` con `default_action = "nvim"`      | Viola separación CLI/editor                   |
| Editar colores en theme.toml directo    | Theme usa flavor — cambios deben ir en flavor |
| `plugin <name>` sin symlink plugins/    | Silently fails, sin notificación              |

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

**Por qué:** En Yazi 26.x el nombre interno cambió de `manager` a `mgr`. Una sección `[manager]` se parsea sin error pero sus keybinds nunca se cargan. Las capas válidas de keymap en 26.x son: `mgr`, `tasks`, `spot`, `pick`, `input`, `confirm`, `help`, `cmp`. No existe una capa `[select]` (el picker es `[pick]`); una sección `[select]` también se ignora sin error.

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
- bypass, clipboard, lazygit, glow, hexyl, mediainfo, mount, ouch, piper, rich-preview

**Plugins con setup():**
- relative-motions, recycle-bin, gvfs, what-size, yatline
- fr: `setup()` es opcional — esta config no lo invoca (funciona con los defaults)

**Nunca hacer:**
```lua
require("bypass"):setup()        -- ← crash en runtime
require("lazygit"):setup()       -- ← crash en runtime
```

---

## I-04 — Yazi es CLI puro — sin integración Neovim desde plugins

**Regla:** Ningún plugin debe delegar acciones a Neovim directamente.

**Por qué:** Neovim y Yazi son herramientas independientes. Yazi abre archivos con su opener (`nvim` en el opener `edit`), pero los plugins no deben invocar nvim internamente.

**Caso concreto — búsqueda de contenido (`fr`):** `lpnh/fr` (rg/rga + fzf + preview con bat) hace `reveal` del resultado en Yazi — navega al archivo, nunca abre el editor. Cualquier reemplazo futuro debe mantener ese comportamiento.

> Histórico: el plugin anterior, `fg.yazi`, exponía `default_action`; la config usaba `"jump"` (nunca `"nvim"`). Se reemplazó por `fr` (ver I-10).

El opener `edit` (nvim) sigue disponible manualmente con `Enter`/`l`.

---

## I-05 — Filetype rules: `is =` requiere acompañante `url` o `mime`

**Regla:** En `[filetype]` rules, `is =` nunca puede ser el único campo selector. Siempre debe ir acompañado de `url` o `mime`.

**Por qué:** En Yazi 26.x, la validación requiere al menos uno de `url` o `mime`. Un entry con solo `is =` genera "at least one of `url` or `mime` must be specified" y Yazi no arranca.

```toml
# INCORRECTO — is solo, sin url ni mime
{ is = "link", fg = "cyan" }
{ is = "dir",  fg = "blue" }   ← además, "dir" no es valor válido de is

# INCORRECTO — estilo anidado: se ignora en silencio (sin error, sin color)
{ url = "*", is = "link", style = { fg = "cyan" } }

# CORRECTO — is acompañado de url, claves de estilo PLANAS sobre la regla
{ url = "*",  is = "orphan", fg = "red",   underline = true }
{ url = "*",  is = "link",   fg = "cyan" }
{ url = "*",  is = "exec",   fg = "green", bold = true }
{ url = "*",  is = "hidden", fg = "bright-black" }

# CORRECTO — directorios via url con barra final
{ url = "*/", fg = "blue", bold = true }

# CORRECTO — mime con el patrón del preset upstream
{ mime = "**/image/*", fg = "bright-magenta" }
```

**Semántica de `url` en 26.x:**
- `url = "*/"` (barra final) → solo directorios. `url = "*"` → solo archivos (nunca matchea directorios).
- Los patrones de `url` se comparan contra la ruta completa: `url = ".*"` nunca matcheó ocultos. Para ocultos usar `is = "hidden"`.
- No usar `mime = "inode/directory"`: en 26.x los directorios tienen mime `folder/*`. Usar `url = "*/"`.

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

## I-09 — Yazi 26.x: `tab_width` eliminado de `[mgr]` en flavor

**Regla:** El campo `tab_width` ya no es válido en la sección `[mgr]` (antes `[manager]`, ver I-11) de un flavor file.

```toml
# INCORRECTO — genera "data did not match any variant of untagged enum CustomField"
[mgr]
tab_width = 1

# CORRECTO — eliminar la línea; el ancho de tab se controla en yatline via init.lua
```

**Síntoma:** "data did not match any variant of untagged enum CustomField" al arrancar.

---

## I-10 — Yazi 26.x: `ya.mgr_emit` ya no existe — usar `ya.emit`

**Regla:** Todo plugin (de terceros o local, ej. `plugins/simple-mtp.yazi/`) debe emitir comandos con `ya.emit(...)`. `ya.mgr_emit` fue removido en Yazi 26: la tabla `ya` devuelve `nil` para ese campo.

**Síntoma:** comportamiento errático sin crash (ej. `3j`/`5k` saltando a posiciones incorrectas) o el error `attempt to call a nil value (field 'mgr_emit')`.

**Antes de adoptar un plugin:** `rg -n 'mgr_emit' plugins/<name>.yazi/` — si aparece, el plugin no es compatible con 26.x.

**Casos resueltos:**
- `dedukun/relative-motions` (sin mantenimiento desde 2025-07) → reemplazado por el fork `boydaihungst/relative-motions` (usa `ya.emit`/`ui.render`). El fork también está marcado como sin mantenimiento por su autor — vigilar en futuros upgrades.
- `DreamMaoMao/fg.yazi` (archivado 2026-09) → reemplazado por `lpnh/fr` vía `ya pkg`.
- `plugins/simple-mtp.yazi/main.lua` (local) → migrado a `ya.emit`.

---

## I-11 — El theme/flavor ignora en silencio secciones y claves desconocidas

**Regla:** Yazi no reporta error por secciones o claves de theme desconocidas — las secciones desconocidas se tratan como "custom sections" y las claves se descartan. Al actualizar Yazi, comparar `flavors/deadlock.yazi/flavor.toml` contra el preset upstream `theme-dark.toml` de esa versión.

**Renombres del esquema 26.x (aplicados en el flavor):**

| Antes (ignorado en 26.x) | 26.x |
|---|---|
| `[manager]` | `[mgr]` |
| `hovered` / `preview_hovered` | `[indicator] current` / `parent` / `preview` |
| `tab_active` / `tab_inactive` | `[tabs] active` / `inactive` |
| `mode_normal`, `mode_select`, `mode_unset` | `[mode] normal_main/normal_alt`, `select_main/select_alt`, `unset_main/unset_alt` |
| `[status] separator_open/close` | `[status] sep_left` / `sep_right` |
| `permissions_t/r/w/x/s` | `perm_type` / `perm_read` / `perm_write` / `perm_exec` / `perm_sep` |
| `[completion]` | `[cmp]` |
| `[help] on/exec/desc/footer` | `[help] border/chord/action/hovered` |
| `[input] cursor` | (eliminado) |
| `marker_unset` | (eliminado; existe `marker_marked`) |

Secciones nuevas estilizadas con ANSI: `[confirm]`, `[tasks]`, `[which]`, `[spot]`. `[icon] prepend_globs` / `prepend_conds` dentro del flavor sí funcionan.

**Síntoma:** colores que no se aplican sin ningún error (ej. cursor por defecto en reverse, directorios sin negrita). Verificado en vivo: el flavor viejo renderizaba el cursor por defecto; el flavor 26.x renderiza cursor negro sobre azul y directorios azules en negrita.

---

## Anti-patrones conocidos

| Anti-patrón                              | Consecuencia                                  |
|------------------------------------------|-----------------------------------------------|
| `[manager]` en keymap.toml              | Sección ignorada, keybinds no cargan          |
| `plugin name --args=val` en keybind     | Plugin no recibe args, se comporta mal        |
| `is = "..."` solo en filetype rules     | Yazi no arranca (falta url o mime)            |
| `is = "dir"` en filetype rules          | Yazi no arranca ("dir" no es valor válido)    |
| `name =` en previewers/preloaders       | Yazi no arranca (renombrado a `url =`)        |
| `tab_width = 1` en flavor `[mgr]`       | Yazi no arranca (campo eliminado en 26.x)     |
| `require("bypass"):setup()`             | Runtime crash                                 |
| Plugin que abre nvim en vez de navegar  | Viola separación CLI/editor (I-04)            |
| `[select]` en keymap.toml               | Sección ignorada (la capa es `[pick]`)        |
| `style = { ... }` anidado en filetype   | Ignorado en silencio (claves planas, I-05)    |
| `mime = "inode/directory"`              | No matchea dirs en 26.x (usar `url = "*/"`)   |
| `ya.mgr_emit` en plugins                | Removido en 26.x (usar `ya.emit`, I-10)       |
| Claves/secciones de theme pre-26.x      | Ignoradas en silencio (I-11)                  |
| Editar colores en theme.toml directo    | Theme usa flavor — cambios deben ir en flavor |
| `plugin <name>` sin symlink plugins/    | Silently fails, sin notificación              |

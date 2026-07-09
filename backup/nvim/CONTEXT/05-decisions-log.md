# Log de Decisiones Técnicas

Registro de decisiones no-obvias para no repetir errores pasados
o revertir cambios ya razonados.

---

## 2026-03-12 — Refactor: nvim-cmp → blink.cmp

**Problema:** `lspconfig.lua` usaba `cmp_nvim_lsp.default_capabilities()` con
`blink.cmp` activo. `hrsh7th/cmp-nvim-lsp` cargado sin uso real.

**Decisión:** Migración completa a `require("blink.cmp").get_lsp_capabilities()`.
Eliminada dep `hrsh7th/cmp-nvim-lsp` de mason.lua y lspconfig.lua.

**Archivo renombrado:** `nvim-cmp.lua` → `blink-cmp.lua`

---

## 2026-03-12 — lua_ls: workspace delegado a lazydev.nvim

**Problema:** `lspconfig.lua` añadía `workspace.library` y `diagnostics.globals`
manualmente, duplicando lo que `lazydev.nvim` ya inyecta automáticamente.

**Decisión:** Eliminar workspace.library y diagnostics.globals de lua_ls config.
`lazydev.nvim` registra: `$VIMRUNTIME/lua`, `stdpath("config")/lua`,
tipos `vim.*`, `vim.uv`, `Snacks`, `lazy.nvim`.

**Verificar:** `:checkhealth lazydev` — debe mostrar runtime paths correctos.

---

## 2026-03-12 — lazy.nvim checker throttle

**Problema:** `checker = { notify = true }` sin `frequency` → consulta de red
en cada startup + popup de notificación.

**Decisión:** `notify = false`, `frequency = 3600` (una hora). Ver updates con `:Lazy`.
`change_detection.notify = false` — recarga silenciosa.

---

## 2026-03-12 — Paleta light: tokens faltantes

**Problema:** `syntaxLightBlue`, `syntaxBeige`, `syntaxMagenta` ausentes en
la tabla `light` de `colorscheme.lua` → `nil` en highlight groups.

**Decisión:** Añadidos con valores de contraste WCAG AA sobre fondo blanco:
- `syntaxLightBlue = "#0070ba"` (4.5:1)
- `syntaxBeige     = "#7a6a4f"` (4.6:1)
- `syntaxMagenta   = "#b800b8"` (5.1:1)

---

## Avante: NO usar dressing.nvim como dependencia

**Problema:** `stevearc/dressing.nvim` como dep de avante.nvim causa error:
`dressing/select/init.lua: items: expected list-like table`
Dressing hace validación estricta que falla con las tablas no-lista de Avante.

**Decisión:** Eliminar dressing de deps de avante. Snacks maneja `vim.ui.select`
e `vim.ui.input` de forma compatible.

---

## Gemini terminal: NO usar toggle_gemini_cli()

**Problema:** `gemini-cli.nvim`'s `toggle_gemini_cli()` destruye y recrea
la ventana en cada toggle → pierde el estado de la sesión.

**Decisión:** Usar `Snacks.terminal.toggle("gemini", opts)` con `cwd` fijo
a `vim.fn.expand("~")` para que el TID de Snacks sea estable.

```lua
local GEMINI_CWD = vim.fn.expand("~")
Snacks.terminal.toggle("gemini", { cwd = GEMINI_CWD, ... })
```

---

## Claude Code: keymaps en terminal mode via snacks_win_opts

**Problema:** Keymaps definidos en `keys = {}` del spec solo llegan a normal mode.
En terminal mode (`t`) no se procesan keymaps normales.

**Decisión:** Usar `snacks_win_opts.keys` con `mode = "t"` para keymaps
que deben funcionar dentro del terminal de Claude.

```lua
snacks_win_opts = {
    keys = {
        my_key = { "<key>", fn, mode = "t", desc = "..." }
    }
}
```

---

## Snacks: módulos desactivados por conflicto

| Módulo | Razón de desactivación | Alternativa |
|--------|----------------------|-------------|
| `indent` | Conflicto visual con indent-blankline | `indent-blankline.nvim` |
| `scope` | Idem | `indent-blankline.nvim` scope |
| `scroll` | Conflicto con smear-cursor | `smear-cursor.nvim` |
| `words` | Funcionalidad duplicada | `vim-illuminate` |

---

## expandtab: tabs reales (convención del proyecto)

**Problema:** `expandtab = true` producía espacios, contradiciendo la convención
de tabs que se ve en todos los archivos Lua del config.

**Decisión:** `expandtab = false`, `softtabstop = 0`.
Para Python/YAML que requieren espacios → `autocmd FileType` local.

---

## FloatBorder: set doble en my-theme/init.lua

**Estado:** INTENCIONAL. `FloatBorder` se setea dentro de la tabla `groups{}`
y luego se sobreescribe explícitamente al final de `set_groups()`.

**Razón:** Los links a otros highlight groups pueden perder el `bg` en algunos
renderers cuando se usa `link =`. El set directo garantiza que `bg` siempre
es el color correcto del floating window.

**NO eliminar** el segundo set de FloatBorder.

---

## 2026-03-12 — Refactor de keymaps: limpieza ergonómica

**Eliminados:**
- `<S-Left>/<S-Right>` buffer nav — arrow keys = mala ergonomía
- `<leader>wh` / `<leader>wv` splits — duplicaban `<leader>-` y `<leader>|`
- `<leader>mp` en conform.lua — duplicaba `<leader>cf` de keymaps.lua
- `<leader>rs` en lspconfig.lua — movido a `<leader>lr` (grupo `<leader>l`)
- `<leader>cm` Mason — movido a `<leader>lm` (grupo LSP es coherente)

**Añadidos:**
- `]d` / `[d` — navegar diagnósticos (consistente con ]h/[h de gitsigns)
- `<leader>xx` — Trouble toggle principal (el resto de `<leader>x*` ya existía)
- `<leader>lr` — Restart LSP (global, no por buffer)
- `<leader>li` — Toggle inlay hints global
- `<leader>ll` / `<leader>lI` — LspLog / LspInfo
- `<C-s>` extendido a insert y visual mode

**Principios:** Una acción = un atajo. Grupo `<leader>l` activado para LSP globals.

---

## <leader>rs: vim.lsp.stop_client en lugar de :LspRestart

**Problema:** `:LspRestart<CR>` es Vimscript en un contexto todo-Lua.

**Decisión:**
```lua
vim.keymap.set("n", "<leader>rs", function()
    vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
    vim.cmd("edit") -- re-trigger BufReadPre → reactiva el LSP
end, opts)
```

---

## 2026-03-12 — Auditoría LSP profunda: inlay hints y mejoras

**ts_ls:** Añadidos `settings.typescript.inlayHints` y `settings.javascript.inlayHints`
con los 7 parámetros disponibles (`parameterNames="all"`, tipos de variables, retorno,
enums, etc.). Se activan con `<leader>uh` o `<leader>li`.

**gopls:** Añadido `hints` block con 7 categorías (assignVariableTypes,
compositeLiteralFields/Types, constantValues, functionTypeParameters,
parameterNames, rangeVariableTypes).

**clangd:** Añadido `--offset-encoding=utf-16` al cmd para evitar warnings de
conflicto de encoding con otros plugins (noice, nvim-ufo).

**signature_help:** Añadido `border = "rounded"` a `vim.lsp.buf.signature_help()`.
Antes era inconsistente con `hover` (que sí tenía border).

---

## 2026-03-12 — Auditoría 360°: performance y limpieza de plugins

### Bugs corregidos

**noice.lua — Override de nvim-cmp eliminado:**
`["cmp.entry.get_documentation"] = true` intenta parchear un módulo de `hrsh7th/nvim-cmp`
que no existe en este stack (blink.cmp). Causaba error silencioso. Convertido a comentario.

**nvim-lint.lua — Keymap `<leader>l` → `<leader>cl`:**
`<leader>l` es el grupo "lsp" en which-key. Asignarlo directamente sobreescribía el grupo.
Fix: movido a `<leader>cl` (grupo `code`). Actualizado en which-key spec.

### Lazy loading mejorado

| Plugin | Antes | Después | Ganancia |
|--------|-------|---------|----------|
| `nvim-ufo` | sin trigger (startup) | `event=BufReadPost` + `keys=zR/zM` | ~10ms |
| `smear-cursor` | sin trigger (indeterminado) | `event=VeryLazy` | claridad |
| `aerial` | `event=BufReadPost` (cada buffer) | `cmd=AerialToggle` | ~8ms |
| `NvChad/nvim-colorizer` | sin `ft` (todos los buffers) | `ft={html,css,js,...}` | ~5ms |
| `yanky` | `event=BufReadPost` + keys | solo keys | marginal |
| `tailwindcss-colorizer-cmp` | sin trigger | `lazy=true` (dep) | marginal |

**Total estimado: ~25ms de startup savings**

### Limpieza

- Eliminados 3 archivos fantasma (retornaban `{}`):
  `nvim-notify.lua`, `nvim-ts-context-commentstring.lua`, `colorizer.lua`
- `todo-comments.lua`: eliminada dep de `plenary.nvim` (no necesaria en v0.6+)
- `render-markdown.lua`: corregida dep `"nvim-mini/mini.nvim"` (repo inválido)
  → `{ "echasnovski/mini.icons", opts = {} }`
- `nvim-ufo.lua`: keymaps `zR`/`zM` movidos al spec `keys = {}` (patrón lazy.nvim correcto)

---

## 2026-03-12 — Auditoría 360° stack de IA

### copilot.lua — auto_trigger=false

**Problema:** `auto_trigger=true` con `blink.cmp ghost_text=true` → ambos usan `virt_text`
en la misma posición del cursor. Solo uno puede ganar visualmente.

**Decisión:** `auto_trigger=false`. Copilot se activa manualmente con `<M-]>` (next).
blink.cmp ghost_text muestra la primera sugerencia LSP; copilot queda como sugerencia
bajo demanda (más útil para completar funciones largas que para snippets rápidos).

**Para volver a auto_trigger:** cambiar a `true` y deshabilitar `ghost_text` en blink-cmp.lua.

### avante.nvim — event=VeryLazy eliminado + system_prompt

**Cambios:**
- `event="VeryLazy"` eliminado → lazy por `keys={}` (solo carga al primer `<leader>aa`)
- `max_tokens` subido de 4096 → 8096 (respuestas largas de código completo)
- `system_prompt` añadido: contexto de stack, lenguajes, reglas de respuesta

### render-markdown.nvim — soporte panel avante

**Problema:** Panel de avante usa `filetype="Avante"`. render-markdown solo procesaba
`ft={"markdown"}` → respuestas de Claude sin renderizado Markdown.

**Fix:** Añadidos `ft` y `file_types = { "markdown", "Avante" }`.

### codecompanion.nvim — system_prompt añadido

Mismo contexto de estudiante de ingeniería que avante. Reglas: respuestas directas,
código idiomático, diagnóstico antes del fix.

### CLAUDE.md creado en raíz del config

Archivo leído automáticamente por `claudecode.nvim` al operar en este directorio.
Contiene convenciones, estructura de archivos, stack, grupos de keymaps y anti-patrones.

---

## 2026-04-02 — Theme picker persistente estilo NvChad

**Motivación:** Cambiar variante requería editar `init.lua` manualmente.

**Implementación:** `lua/Deadlock/config/theme-picker.lua`
- Ventana flotante con `nvim_open_win` (border rounded, title centrado)
- Preview live: `CursorMoved` autocmd aplica el tema en cada movimiento
- `j`/`k` con skip de headers; `<CR>` confirma; `<Esc>`/`q` revierte

**Persistencia:** `~/.local/share/nvim/my-theme-variant`
- Formato: `nw:<variant>` | `ext:<colorscheme>` | legacy (solo nombre → trata como `nw:`)
- `init.lua` lee el archivo antes de cargar plugins. Si es `ext:*`, aplica Night Wolf
  primero y lanza `VimEnter` autocmd para el colorscheme externo

**Swatches Night Wolf:** 5 colores hardcoded en `NW_PALETTES` (editor_bg, float_bg, kw, fn, str).
Deben recrearse tras cada `apply()` porque `theme.colorscheme()` hace `hi clear`.

**Swatches externos:** leídos dinámicamente de los grupos activos tras aplicar el tema
(`Normal.bg`, `NormalFloat.bg`, `Keyword.fg`, `Function.fg`, `String.fg`). Cacheados en sesión.

---

## 2026-04-02 — Detección de colorschemes en plugins lazy

**Problema:** `vim.fn.getcompletion("", "color")` solo devuelve colorschemes de
plugins ya en el rtp. Con `lazy=true`, lazy.nvim no añade el plugin al rtp hasta
que se carga → tokyonight no aparecía en el picker.

**Decisión:** Combinar dos fuentes en `get_external_colorschemes()`:
1. `getcompletion("", "color")` para plugins ya cargados
2. `vim.uv.fs_scandir(plugin.dir .. "/colors")` para cada plugin en `lazy.core.config.plugins`

Resultado: cualquier plugin de colorscheme aparece en el picker, esté cargado o no.
`vim.cmd.colorscheme()` sobre un plugin lazy lo carga automáticamente (lazy.nvim interception).

---

## 2026-04-02 — Integración barbecue.nvim en my-theme

**Decisión:** Crear `integrations/barbecue.lua` siguiendo el patrón de las otras integraciones.

**Grupos cubiertos:**
- `BarbecueNormal/Dimmed/Basename/Dirname/Ellipsis/Separator/Modified/Context` — winbar base
- `BarbecueContext{Class,Method,Function,...}` — 26 tipos LSP, coloreados con paleta Night Wolf
- `NavicIcons{File,Class,Function,...}` — 26 tipos, misma paleta
- `NavicText` / `NavicSeparator` — texto e iconos de contexto

**Mappings de color:**
- Funciones/métodos/constructores → `syntaxFunction` (cyan)
- Tipos/enums/structs/namespaces → `syntaxKeyword` (violet) / `specialKeyword` (purple)
- Variables/parámetros/arrays → `warningText` (yellow)
- Constantes/booleanos/null → `lightRed`
- Strings → `stringText` (green)
- Números → `warningEmphasis` (orange)
- Interfaces → `syntaxLightBlue`
- `BarbecueBasename` → `emphasisText` bold (nombre del archivo, más prominente)
- `BarbecueDirname`/separators → `inactiveText` (muted)

**`attach_navic=true`** en `opts` de barbecue → se auto-adjunta a cada cliente LSP
sin necesitar on_attach manual.

---

## 2026-04-03 — Theme picker: migración a snacks.picker + soporte de colorschemes externos

**Motivación:** El picker original usaba `nvim_open_win` / `nvim_buf_set_lines` manual.
Se migró a `snacks.picker` para consistencia con el resto del config y para ganar
fuzzy search nativo.

**Cambios principales:**
- `finder` retorna lista de items `{ text, kind, name }` donde `kind = "nw" | "ext" | "sep"`
- Preview live via `on_change` debounced 80ms (antes: `CursorMoved` autocmd)
- `on_close` revierte automáticamente si no se confirmó
- Sección `── plugins ──` con colorschemes descubiertos en `lazy.core.config.plugins`
- Indicadores `▶` (activo), `●` (guardado), ` ` (sin marcar) en `format`
- El item activo al abrir el picker flota al primer lugar de la lista NW

**Persistencia:** sin cambios — mismo formato `nw:` / `ext:` en `my-theme-variant`.

---

## 2026-04-03 — lazy.load() → vim.opt.rtp:append para colorschemes

**Problema:** Al seleccionar un tema externo (ej. catppuccin) desde el picker o al
restaurar en startup, se emitía: `"Lua module not found for config of nvim. Please
use a config() function instead"`. Funcional pero ruidoso.

**Causa raíz:** `require("lazy").load({ plugins = { name } })` no solo añade el plugin
al rtp — también ejecuta el auto-config de lazy. Para plugins cuyo repo se llama `nvim`
(como `catppuccin/nvim`), lazy intenta `require("nvim").setup(opts)` que falla.

**Decisión:** Usar `vim.opt.rtp:append(plugin.dir)` directamente. Para colorschemes
solo necesitamos el directorio en rtp; no queremos que lazy ejecute nada más.

**Patrón `lazy_load_for(cs_name)`** (duplicado en `init.lua` y `theme-picker.lua`):
```lua
local function lazy_load_for(cs_name)
    local ok, lazy_cfg = pcall(require, "lazy.core.config")
    if not ok then return end
    for _, plugin in pairs(lazy_cfg.plugins) do
        if plugin.dir then
            local cd = plugin.dir .. "/colors/"
            if vim.fn.filereadable(cd .. cs_name .. ".lua") == 1
                or vim.fn.filereadable(cd .. cs_name .. ".vim") == 1 then
                vim.opt.rtp:append(plugin.dir)
                return
            end
        end
    end
end
```

---

## 2026-04-03 — nvim-highlight-colors: render foreground por performance

**Problema:** Con archivos con muchos colores (ej. archivos CSS grandes), mover el
cursor línea a línea producía lag perceptible.

**Causa:** `render = "virtual"` con `virtual_symbol_position = "inline"` inserta
extmarks dentro del flujo del texto. Neovim recalcula el layout de cada línea afectada
en cada redraw, que incluye scrolling y movimiento de cursor.

**Decisión:** Cambiar a `render = "foreground"`. El texto del valor hex/rgb/hsl
se colorea con su propio color como `fg` del highlight group. No hay virtual text,
no hay recálculo de layout → redraws significativamente más ligeros.

**Tradeoff visual:** Ya no aparece el símbolo `■` flotante. El color se lee directamente
del texto del valor. Si se prefiere el símbolo, usar `render = "virtual"` a costa del
rendimiento.

**Otras optimizaciones en el mismo cambio:**
- `enable_var_usage = false` — el plugin escanea el buffer entero en cada cambio
  para resolver `--css-variable` references. Alto costo, bajo valor fuera de CSS.
- Auto-disable para archivos > 100 KB via `BufReadPost` + `HighlightColors Off/On`
  en BufEnter/BufLeave del buffer grande.

---

## 2026-04-03 — nvim-highlight-colors reemplaza NvChad/nvim-colorizer

**Razón del cambio:** `nvim-highlight-colors` ofrece integración nativa con `blink.cmp`
via override del componente `kind_icon`. Cuando el item de completion es un color LSP,
el ícono se convierte en un swatch del color real usando `hl.format(ctx.item.documentation)`.
`nvim-colorizer.lua` no tiene esta integración.

**Integraciones activas:**
- Buffer: hex, short_hex, rgb, hsl, tailwind (enabled)
- Blink dropdown: `kind_icon.text` y `kind_icon.highlight` en `blink-cmp.lua`
- Exclusiones: lazy, mason, dashboard, help, snacks UI windows, oil, trouble, qf

---

## @lsp.type.keyword: vacío intencional

En `my-theme/init.lua`, el grupo `["@lsp.type.keyword"] = {}` está vacío
deliberadamente. Si tuviera un valor, el LSP sobreescribiría los colores
de keywords del tree-sitter (que son más precisos por contexto).
LSP semantic tokens tienen priority 125 > TS 100, así que un grupo vacío
deja que TS "gane" para keywords.

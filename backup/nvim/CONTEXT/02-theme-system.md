# Sistema de Tema — Night Wolf

## Archivos del tema

```
lua/Deadlock/my-theme/
├── init.lua          ← API pública: theme.setup() + theme.colorscheme()
├── config.lua        ← variante activa, opciones italics, overrides
├── colorscheme.lua   ← paletas dark/light + escalas por variante
├── utils.lua         ← shade(color, factor, bg), mix(a, b, factor)
├── types.lua
└── integrations/
    ├── avante.lua    ← highlights para paneles y botones de Avante
    ├── barbecue.lua  ← NavicIcons* + BarbecueNormal/Context/Dirname/etc.
    ├── bufferline.lua← highlights para tabs (usa config.italics.bufferline)
    ├── cmp.lua       ← highlights para menú de completion (kind icons)
    ├── lsp.lua       ← FloatBorder, inlay hints, hover windows
    └── noice.lua     ← cmdline popup, borders
```

## Variantes disponibles

| Variante | Fondo | Transparente | Notas |
|----------|-------|--------------|-------|
| `default` | `none` | ✅ | Dark + transparencia de terminal |
| `black` | `#0a0a0a` | ❌ | Negro puro. **Default si no hay guardado** |
| `dark` | `#1b1b1b` | ❌ | Gris oscuro, text `#cecece` |
| `darker` | `#252525` | ❌ | Gris medio |
| `dark_blue` | `#101e2c` | ❌ | Azul oscuro, text `#bdd2e7` |
| `light` | `#ffffff` | ❌ | Blanco |
| `light_transparent` | `none` | ✅ | Light + transparencia |
| `terminal` | dinámica | ✅ | Colores leídos desde caelestia sequences (`my-theme/terminal.lua`); fallback a `default` si el archivo no está disponible |

Para cambiar variante **en runtime**: `<leader>uv` (picker flotante con preview live).
La selección se persiste en `~/.local/share/nvim/my-theme-variant`.

## Theme Picker (`lua/Deadlock/config/theme-picker.lua`)

Picker via `snacks.picker` con preview live al navegar y soporte de colorschemes externos.

```
╭─── Theme Variant ──────────────╮
│  ▶ black                       │  ← activo
│    dark                        │
│    dark_blue                   │
│  ── plugins ──                 │  ← sección separadora
│  ● catppuccin-mocha            │  ← guardado (●), no activo
│    tokyonight                  │
╰────────────────────────────────╯
```

**Indicadores de formato:**
- `▶ ` — tema actualmente activo (live preview / último aplicado)
- `● ` — tema guardado en disco (se cargará al próximo arranque)
- `   ` — sin marcar

**Preview live:** `on_change` debounced 80ms aplica el tema completo al mover cursor.
**Cancelar (`<Esc>`):** `on_close` revierte al tema que estaba activo al abrir el picker.
**Confirmar (`<CR>`):** guarda en disco y cierra. Notificación via snacks.

**Persistencia:** `~/.local/share/nvim/my-theme-variant`
- Formato: `nw:<variant>` | `ext:<colorscheme>` | legacy (solo nombre → trata como `nw:`)

**Sección NW:** variantes hardcoded en `VARIANTS = { "default", "black", ... }`.
El elemento activo flota al inicio de la lista.

**Sección plugins:** escaneo de `colors/*.lua|vim` en cada `plugin.dir` de
`lazy.core.config.plugins`. Captura plugins `lazy=true` no cargados aún en rtp.
Los items tienen `kind = "ext"`.

**Carga de plugins lazy:** `lazy_load_for(cs_name)` usa `vim.opt.rtp:append(plugin.dir)`
(NO `lazy.load()`) para añadir el plugin al rtp sin disparar su auto-config.

## Restauración al arranque (`init.lua` raíz)

```lua
-- Lee nw:<variant> | ext:<colorscheme> | <legacy-name>
-- Si ext: → aplica Night Wolf primero, luego colorscheme externo via User VeryLazy
```

- Si `nw:*`: `theme.setup({ variant = name })` + `theme.colorscheme()` inmediatamente.
- Si `ext:*`: Night Wolf como tema temporal + `User VeryLazy` autocmd que llama
  `apply_external(name)`. Este helper:
  1. Llama `lazy_load_for(cs_name)` → `vim.opt.rtp:append(plugin.dir)` para meter
     el plugin en rtp sin ejecutar su config
  2. Para variantes `tokyonight-<style>`: `require("tokyonight").setup({ style = ... })`
     + `vim.cmd.colorscheme("tokyonight")`
  3. Para otros: `pcall(vim.cmd.colorscheme, name)` con notify en fallo

**Por qué VeryLazy y no VimEnter:** lazy.nvim registra sus plugins en `VimEnter`.
`User VeryLazy` se dispara después, garantizando que `lazy.core.config.plugins`
está completo y `lazy_load_for` puede encontrar el plugin correcto.

## Paleta Dark (Night Wolf original)

| Token | Hex | Uso principal |
|-------|-----|---------------|
| `mainText` | `#c8c8c8` | Texto normal |
| `emphasisText` | `#ffffff` | Texto énfasis, borders |
| `commentText` | `#647882` | Comentarios |
| `syntaxFunction` | `#00dcdc` | Funciones, métodos (cyan) |
| `syntaxKeyword` | `#9696ff` | Keywords, namespaces (violet) |
| `specialKeyword` | `#dc8cff` | if/else/switch, Types (purple) |
| `lightRed` | `#ff7878` | Constantes, operadores, booleans |
| `warningEmphasis` | `#ffb482` | Números, instancias de variable (orange) |
| `warningText` | `#ffdc96` | Variables, parámetros (yellow) |
| `stringText` | `#aae682` | Strings (green) |
| `linkText` | `#00b1ff` | import/export, var/let/const (blue) |
| `syntaxLightBlue` | `#86e0f4` | CSS variables, LSP interfaces |
| `syntaxBeige` | `#dbd4ba` | Regex literals |
| `syntaxMagenta` | `#ff50ff` | ANSI terminal magenta |
| `property` | `#ffdc96` | Fields/properties (= warningText) |

## Paleta Light

Mismos tokens pero con valores ajustados para fondo blanco.
Tokens añadidos en refactor 2026-03-12 (antes ausentes → nil):
- `syntaxLightBlue = "#0070ba"` — ratio 4.5:1 sobre #fff
- `syntaxBeige = "#7a6a4f"` — ratio 4.6:1
- `syntaxMagenta = "#b800b8"` — ratio 5.1:1

## Orden de aplicación de highlights

```
1. set_groups()           ← todos los grupos base + integraciones
2. set_background_transparent()  ← SOLO en variantes transparentes
                                    sobreescribe Normal, NormalFloat,
                                    SignColumn, CursorLine, etc.
```

El `FloatBorder` se setea DOS VECES en `set_groups()` (al final):
```lua
-- Necesario: los links a otros grupos pueden perder bg en algunos renderers
api.nvim_set_hl(0, "FloatBorder", { fg = colorscheme.emphasisText, bg = ... })
```
Esto es INTENCIONAL, no eliminarlo.

## Overrides personalizados

En `init.lua` (raíz), dentro de `theme.setup()`:
```lua
theme.setup({
    variant = "default",
    italics = {
        comments  = true,
        keywords  = true,
        functions = false,  -- ← desactivado por preferencia estética
        strings   = false,
        variables = false,
    },
    -- overrides = function()  -- para highlights custom adicionales
    --     return { Normal = { bg = "#ff0000" } }
    -- end,
})
```

## Overrides de lenguaje específico

Definidos en `my-theme/init.lua` dentro de `set_groups()`:

### Lua
- `@function.call.lua`, `@function.builtin.lua` → `mainText` (sin color)
- Razón: VSCode NightWolf tampoco colorea function calls en Lua

### JS/TS
- `@variable.builtin.{javascript,typescript,tsx,jsx}` → `lightRed` (this/self)
- `@keyword.storage.{javascript,typescript}` → `linkText` italic (var/let/const)

### Go
- `@keyword.go`, `@keyword.import.go`, `@keyword.function.go` → `linkText` italic
- `@type.go` → `warningText` (custom types en amarillo)
- `@module.go` → `warningText` (packages)

### CSS/SCSS
- `@property.css` → `syntaxFunction` (cyan)
- `@variable.css`, `@variable.scss` → `syntaxLightBlue`
- `@tag.css` → `lightRed`

## Colores de terminal (16-color ANSI)

Mapeados exactamente a la paleta Night Wolf para coherencia en terminals
embebidos (`terminal_color_0..15` en `set_terminal_colors()`).

## Integración con bufferline

`theme.bufferline.highlights` se genera en `theme.setup()` y debe pasarse
a bufferline via su opción `highlights`:
```lua
-- en bufferline.lua:
opts = {
    highlights = require("Deadlock.my-theme.init").bufferline.highlights,
}
```

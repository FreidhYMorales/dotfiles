# Arquitectura General — Neovim Config

## Árbol de carga (startup order)

```
init.lua
├── my-theme/init.lua          ← PRIMERO: define todos los highlight groups
│   ├── colorscheme.lua        ← paleta Night Wolf (dark/light por variante)
│   ├── config.lua             ← variante activa + opciones italics/overrides
│   ├── utils.lua              ← shade(), mix() para colores derivados
│   └── integrations/
│       ├── avante.lua
│       ├── bufferline.lua
│       ├── cmp.lua
│       ├── lsp.lua
│       └── noice.lua
│
└── Deadlock.config            ← SEGUNDO: lazy.nvim + vim.opt + keymaps
    ├── lazy.lua               ← bootstrap lazy.nvim, importa plugins/
    ├── options.lua            ← vim.opt settings
    ├── keymaps.lua            ← keymaps globales
    └── autocmd.lua            ← autocommands globales

lua/Deadlock/plugins/          ← specs de plugins (lazy.nvim auto-import)
lua/Deadlock/plugins/lsp/      ← mason.lua + lspconfig.lua (sub-módulo)
```

## Convenciones ESTRICTAS del proyecto

| Aspecto | Valor | Razón |
|---------|-------|-------|
| Indentación | **tabs reales** (`expandtab=false`, `tabstop=4`) | Convención histórica |
| Completion bridge | `require("blink.cmp").get_lsp_capabilities()` | Stack es blink.cmp, NO nvim-cmp |
| Terminals | `Snacks.terminal.*` | Provider unificado; evitar window destroy/recreate |
| Pickers | `require("snacks").picker.*` | Reemplazó Telescope para la mayoría de casos |
| Input/Select | `snacks` input/selector | NO usar dressing.nvim (conflicto con avante) |
| Notificaciones | `snacks.notifier` | NO nvim-notify standalone |
| File explorer | `oil.nvim` (primario) + `snacks.explorer` (secundario) | |

## Principios de lazy-loading

- `lazy = false` solo para: `snacks.nvim` (priority=1000) y `blink.nvim` (meta-plugin)
- LSP + treesitter: evento `BufReadPre, BufNewFile`
- UI extras: evento `VeryLazy`
- Keymaps: clave `keys = {}` en el spec (lazy.nvim lazy-load por keymap)
- NUNCA usar `event = "UIEnter"` para plugins pesados

## Estructura de archivos de plugins

Cada archivo en `lua/Deadlock/plugins/` retorna una tabla lazy.nvim spec.
Patrón preferido:

```lua
return {
    "autor/plugin",
    event = "...",         -- trigger de carga
    dependencies = { ... },
    opts = { ... },        -- si el plugin usa setup() simple
    -- config = function(_, opts)  -- solo si necesitas lógica extra
    keys = { ... },        -- keymaps declarados aquí para lazy-load
}
```

## Módulos de configuración core

| Archivo | Responsabilidad |
|---------|-----------------|
| `options.lua` | Solo `vim.opt.*` y `vim.g.*` sin side-effects |
| `keymaps.lua` | Keymaps globales (no-buffer). Variable local: `local key = vim.keymap.set` |
| `autocmd.lua` | Autocommands globales. Variables: `local acmd`, `local augroup` |
| `lazy.lua` | Bootstrap + `require("lazy").setup({...})`. Nada más |

## Convenciones de keymaps

### Dónde va cada keymap

| Tipo | Ubicación |
|------|-----------|
| Global (todos los buffers) | `keymaps.lua` |
| Buffer-local LSP | `LspAttach` en `lsp/lspconfig.lua` |
| Plugin-specific | `keys = {}` en el spec lazy del plugin |
| Terminal-mode | `snacks_win_opts.keys` con `mode = "t"` |

### Convenciones Lua nativa (desde refactor 2026-03-12)

```lua
-- ✅ Lua nativa
vim.cmd.quit()
vim.cmd.enew()
vim.fn.system("chmod +x " .. vim.fn.shellescape(file))
vim.notify("mensaje", vim.log.levels.INFO)
require("snacks").bufdelete()

-- ❌ Vimscript en string (evitar salvo que no haya API equivalente)
"<cmd>q<CR>"
"<cmd>!chmod +x %<CR>"
print("mensaje")
"<cmd>bd<CR>"
```

### Grupos which-key — reglas de nemotecnia

```
<leader>a  → AI        (avante, claude, gemini, opencode, codecompanion)
<leader>b  → Buffer    (delete, navigate)
<leader>c  → Code      (format, actions, diagnostics float, symbols)
<leader>d  → Debug     (DAP breakpoints, step, UI)
<leader>e  → Explorer  (oil, snacks, blink-tree)
<leader>f  → File      (new, path, chmod)
<leader>g  → Git       (hunks, blame, diff, lazygit)
<leader>h  → Harpoon   (add, menu, jump 1-5)
<leader>l  → LSP       (restart, hints, log, info, mason)
<leader>p  → Picker    (files, grep, keymaps, todos)
<leader>q  → Quit      (session save/restore + quit variants)
<leader>r  → Rename    (symbol rename, file rename, restart)
<leader>s  → Search    (substitute, grug-far)
<leader>u  → UI        (toggle: diagnostics, format, hints, context)
<leader>v  → View      (help pages)
<leader>w  → Window    (splits, proxy <C-w>)
<leader>x  → diX       (Trouble: diag, quickfix, symbols)
<leader>z  → Zen
```

### Separación LSP: global vs buffer-local

```
keymaps.lua (<leader>l*):
  <leader>lr  Restart LSP         → para todo el editor
  <leader>li  Toggle inlay hints   → global (todos los buffers)
  <leader>ll  LspLog
  <leader>lI  LspInfo
  <leader>lm  Mason

lspconfig.lua (LspAttach — buffer-local):
  gd gD gR gi gt    → navegación de definiciones
  K                 → hover doc
  <leader>ca        → code actions
  <leader>rn        → rename
  <leader>uh        → inlay hints (solo buffer actual)
  <C-h>             → signature help (insert)
```

### Navegación bracket `[` / `]` — convención unificada

```
[b / ]b   buffers          (nativo)
[d / ]d   diagnósticos     (vim.diagnostic)
[h / ]h   hunks git        (gitsigns)
[q / ]q   quickfix/trouble (trouble.nvim)
[t / ]t   TODOs            (todo-comments)
```

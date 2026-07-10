# Inventario de Plugins

## Plugins críticos (lazy=false / priority alta)

| Plugin | Rol | Notas |
|--------|-----|-------|
| `folke/snacks.nvim` | UI core: terminals, pickers, notifier, dashboard, input, explorer | `priority=1000, lazy=false` |
| `saghen/blink.nvim` | Meta-plugin: chartoggle + blink-tree | `lazy=false` (módulos manejan su propio lazy) |

## Completion stack

| Plugin | Archivo | Rol |
|--------|---------|-----|
| `saghen/blink.cmp` | `blink-cmp.lua` | Motor de completion principal |
| `L3MON4D3/LuaSnip` | dep de blink-cmp | Snippet engine (`v2.*`) |
| `rafamadriz/friendly-snippets` | dep de LuaSnip | Snippets predefinidos |
| `saghen/blink.compat` | dep de blink-cmp | Bridge para sources de nvim-cmp |
| `f3fora/cmp-spell` | dep de blink-cmp | Source de spell (markdown/text only) |

**Completion file:** `blink-cmp.lua` (renombrado de `nvim-cmp.lua` en 2026-03-12).

## LSP stack

| Plugin | Archivo | Rol |
|--------|---------|-----|
| `williamboman/mason.nvim` | `lsp/mason.lua` | Instala LSP servers + tools |
| `williamboman/mason-lspconfig.nvim` | dep de mason | Bridge mason ↔ lspconfig |
| `WhoIsSethDaniel/mason-tool-installer.nvim` | dep de mason | Instala formatters/linters |
| `neovim/nvim-lspconfig` | `lsp/lspconfig.lua` | Defaults de servidores |
| `folke/lazydev.nvim` | `lazydev.lua` | Tipos Lua para nvim API en lua_ls |
| `antosha417/nvim-lsp-file-operations` | dep de lspconfig | Rename de archivos via LSP |

## AI Tools

| Plugin | Archivo | Keymap | Lazy trigger | Rol |
|--------|---------|--------|--------------|-----|
| `yetone/avante.nvim` | `avante.lua` | `<leader>aa*` | `keys` (antes VeryLazy) | Diff visual interactivo |
| `coder/claudecode.nvim` | `claude-code.lua` | `<leader>ac*` | `keys` | Agente autónomo CLI |
| Gemini CLI | `gemini.lua` | `<leader>ag*` | `keys` | Terminal conversacional |
| `NickvanDyke/opencode.nvim` | `opencode.lua` | `<leader>ao*` | `keys` | Agente multi-modelo |
| `olimorris/codecompanion.nvim` | `codecompanion.lua` | `<leader>an*` | `cmd+keys` | Chat largo + MCP |
| `zbirenbaum/copilot.lua` | `copilot.lua` | `<M-]/[/l/j/k>` | `InsertEnter+keys` | Inline bajo demanda |

**Avante:** No usar `stevearc/dressing.nvim` como dep — conflicto con snacks `vim.ui.select`.

**Avante system_prompt:** Configurado para Estudiante de Ingeniería. `max_tokens=8096`.

**Copilot:** `auto_trigger=false` — evita conflicto de `virt_text` con blink.cmp `ghost_text`.
Activación manual con `<M-]>`. Para volver a auto, cambiar `auto_trigger=true` y
desactivar `ghost_text` en `blink-cmp.lua`.

**CodeCompanion system_prompt:** Mismo contexto técnico que avante. Usa `snacks` como
provider de pickers internos.

**CLAUDE.md:** Archivo en raíz leído automáticamente por claudecode.nvim. Contiene
convenciones, anti-patrones y estructura del proyecto.

## Formatting & Linting

| Plugin | Archivo | Trigger | Keymap |
|--------|---------|---------|--------|
| `stevearc/conform.nvim` | `conform.lua` | `BufWritePre` (auto-format on save) | `<leader>cf` manual, `<leader>uf` toggle |
| `mfussenegger/nvim-lint` | `nvim-lint.lua` | `BufEnter, BufWritePost, InsertLeave` | `<leader>cl` manual |

## Treesitter

| Plugin | Archivo | Rol |
|--------|---------|-----|
| `nvim-treesitter/nvim-treesitter` | `treesitter.lua` | Parser + highlighting (30+ langs) |
| `nvim-treesitter/nvim-treesitter-context` | `treesitter-context.lua` | Contexto sticky en top |
| `windwp/nvim-ts-autotag` | `nvim-ts-autotag.lua` | Auto-close/rename HTML tags |
| `folke/ts-comments.nvim` | `ts-comments.lua` | Comentarios por contexto (reemplazó nvim-ts-context-commentstring) |
| `hiphish/rainbow-delimiters.nvim` | `rainbow-delimiters.lua` | Paréntesis en colores Night Wolf |

## Navigation & Motion

| Plugin | Archivo | Keymaps principales |
|--------|---------|---------------------|
| `folke/flash.nvim` | `flash.lua` | `s/S` jump, `r` remote, `R` TS search |
| `ThePrimeagen/harpoon` | `harpoon.lua` | `<leader>ha` add, `<leader>hh` menu, `<leader>1-5` |
| `stevearc/oil.nvim` | `oil.lua` | `\\`, `<leader>e` — explorador primario |
| `vim-maximizer` | `vim-maximizer.lua` | `<leader>sm` maximizar split |

## UI / Visual

| Plugin | Archivo | Rol |
|--------|---------|-----|
| `folke/noice.nvim` | `noice.lua` | Command UI, search bottom |
| `akinsho/bufferline.nvim` | `bufferline.lua` | Buffer tabs |
| `nvim-lualine/lualine.nvim` | `lualine.lua` | Statusline |
| `utilyre/barbecue.nvim` | `barbecue.lua` | Winbar breadcrumbs con iconos LSP |
| `SmiteshP/nvim-navic` | dep de barbecue | Contexto LSP para la winbar |
| `b0o/incline.nvim` | `incline.lua` | Nombre de archivo en float |
| `folke/which-key.nvim` | `which-key.lua` | Guía de keymaps (preset: helix) |
| `lukas-reineke/indent-blankline.nvim` | `indent-blankline.lua` | Guías de indentación |
| `RRethy/vim-illuminate` | `vim-illuminate.lua` | Highlight referencias bajo cursor |
| `sphamba/smear-cursor.nvim` | `smear.lua` | Animación de cursor (`event=VeryLazy`) |
| `brenoprata10/nvim-highlight-colors` | `nvim-highlight-colors.lua` | Preview inline de hex/rgb/hsl/tailwind; `render="foreground"`; integrado con blink.cmp `kind_icon` para swatches en el dropdown |
| `folke/twilight.nvim` | `twilight.lua` | Dim de secciones inactivas |
| `folke/zen-mode.nvim` | `zen-mode.lua` | Focus mode (`<leader>z`) |

**barbecue.nvim:** `attach_navic=true` (auto-attach al LSP), `show_modified=true`.
Carga en `BufReadPost`. Integración my-theme en `integrations/barbecue.lua` cubre
los 26 grupos `NavicIcons*` + `NavicText`/`NavicSeparator` + 8 grupos `Barbecue*`
+ los 26 `BarbecueContext*` por tipo LSP.

## Git

| Plugin | Archivo | Keymaps |
|--------|---------|---------|
| `lewis6991/gitsigns.nvim` | `gitsigns.lua` | `<leader>gh*` — hunks, blame, stage |
| `sindrets/diffview.nvim` | `diffview.lua` | `<leader>gd`, `<leader>gf/gF` |
| Lazygit (via snacks) | `snacks.lua` | `<leader>lg`, `<leader>gl` |

## Code Tools

| Plugin | Archivo | Keymaps |
|--------|---------|---------|
| `stevearc/aerial.nvim` | `aerial.lua` | `<leader>cs` símbolos/outline (`cmd=AerialToggle`, no event) |
| `folke/trouble.nvim` | `trouble.lua` | `<leader>x*` diagnósticos, quickfix |
| `mfussenegger/nvim-dap` | `nvim-dap.lua` | `<leader>d*` debug |
| `folke/todo-comments.nvim` | `snacks.lua` | `<leader>pt/pT` via snacks picker |
| `kevinhwang91/nvim-ufo` | `nvim-ufo.lua` | Folding avanzado (TS + indent) — `event=BufReadPost`, `zR/zM` en spec |
| `mbbill/undotree` | `undo-tree.lua` | `<leader>u` undo tree |
| `MagicDuck/grug-far.nvim` | `grug-far.lua` | `<leader>sr` search & replace interactivo |

## Text Objects & Surround

| Plugin | Archivo | Keymaps |
|--------|---------|---------|
| `echasnovski/mini.ai` | `mini-ai.lua` | Text objects: `o`=block, `f`=fn, `c`=class |
| `echasnovski/mini.surround` | `mini-surround.lua` | `gs[a/d/f/h/r]` surround |

## Snippets / Editing

| Plugin | Archivo | Keymaps/Notas |
|--------|---------|---------------|
| `windwp/nvim-autopairs` | `autopairs.lua` | Auto-pares con integración TS |
| `max397574/better-escape.nvim` | `better-escape.lua` | `jk`/`jj` escape en insert/cmd/term |
| `gbprod/yanky.nvim` | `yanky.lua` | Historial de yank (`<leader>py`) |
| `chrisgrieser/nvim-rip-substitute` | `rip.lua` | `<leader>fs` ripgrep substitute |

## Misc

| Plugin | Archivo | Notas |
|--------|---------|-------|
| `folke/persistence.nvim` | `persistence.lua` | Sesiones (`<leader>qs/qS/ql/qd`) |
| `luckasRanarison/tailwind-tools.nvim` | `tailwind.lua` | Preview Tailwind en editor + completion |
| `MeanderingProgrammer/render-markdown.nvim` | `render-markdown.lua` | Render de markdown en buffer + panel de Avante (`ft=Avante`) |
| `antosha417/nvim-lsp-file-operations` | dep lspconfig | Rename archivos via LSP |
| `amrbashir/nvim-docs-view` | `nvim-docs-view.lua` | Panel LSP docs (`cmd=DocsViewToggle`) |

## Snacks — módulos activos

```lua
snacks = {
    notifier  = true,    -- reemplaza nvim-notify
    picker    = true,    -- reemplaza Telescope para la mayoría de casos
    explorer  = true,    -- explorador secundario (<leader>es)
    input     = true,    -- reemplaza vim.ui.input
    quickfile = true,    -- fast buffer open
    dashboard = true,    -- pantalla inicial con ASCII "DEADLOCK"
    terminal  = true,    -- provider de terminales (Gemini, Claude, etc.)
    image     = true,    -- imágenes en markdown (requiere magick)
    -- DESACTIVADOS:
    indent    = false,   -- → indent-blankline.nvim
    scope     = false,   -- → indent-blankline.nvim scope
    scroll    = false,   -- → smear-cursor.nvim
    words     = false,   -- → vim-illuminate
}
```

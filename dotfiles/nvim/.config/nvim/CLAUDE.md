# Neovim Config — Contexto para IA

Este archivo es leído automáticamente por Claude Code (`claudecode.nvim`) al operar
en este directorio. También sirve como referencia manual para avante y codecompanion.

## Identidad del proyecto

Configuración de Neovim de un **Estudiante de Ingeniería en Ciencias de la Computación**
(Arch Linux / Hyprland / Wayland). Todo el código es Lua.

## Convenciones ESTRICTAS — nunca violarlas

| Regla | Valor |
|-------|-------|
| Indentación | **tabs reales** (`expandtab=false`) |
| Completion | `require("blink.cmp").get_lsp_capabilities()` — NO cmp_nvim_lsp |
| Keymaps en plugins | `keys = {}` en el spec lazy.nvim |
| Keymaps globales | `lua/Deadlock/config/keymaps.lua` |
| Notificaciones | `snacks.notifier` — NO nvim-notify standalone |
| Pickers | `require("snacks").picker.*` — NO telescope salvo :Telescope themes |
| Terminales | `Snacks.terminal.*` — NO toggleterm |
| Input/select | `snacks` — NO dressing.nvim |

## Estructura de archivos

```
init.lua                          ← carga my-theme PRIMERO, luego Deadlock.config
lua/Deadlock/
  config/
    lazy.lua                      ← bootstrap lazy.nvim
    options.lua                   ← vim.opt.* sin side-effects
    keymaps.lua                   ← keymaps globales (local key = vim.keymap.set)
    autocmd.lua                   ← autocommands globales
  plugins/                        ← specs lazy.nvim (un archivo por plugin)
    lsp/
      mason.lua                   ← mason + mason-lspconfig + mason-tool-installer
      lspconfig.lua               ← vim.lsp.config + vim.lsp.enable por servidor
  my-theme/                       ← tema Night Wolf custom (paleta dark/light)
CONTEXT/                          ← documentación técnica interna
```

## Stack de plugins clave

- **Completion**: `saghen/blink.cmp` (NOT nvim-cmp)
- **LSP**: `neovim/nvim-lspconfig` + mason + `vim.lsp.config()` nativo (Nvim 0.11+)
- **UI core**: `folke/snacks.nvim` (terminals, pickers, notifier, dashboard, input)
- **AI**: avante (diff), claudecode (agente), codecompanion (chat), copilot (inline)
- **Formatter**: `stevearc/conform.nvim` (format-on-save)
- **Linter**: `mfussenegger/nvim-lint`
- **Color preview**: `brenoprata10/nvim-highlight-colors` (hex/rgb/hsl/tailwind inline, `render="foreground"`, integrado con blink.cmp kind_icon)

## Servidores LSP activos

lua_ls, ts_ls, html, cssls, tailwindcss, gopls, pyright, clangd, bashls,
csharp_ls, angularls, emmet_ls, marksman

## Grupos de keymaps (`<leader>`)

```
a → AI tools (aa=avante, ac=claude, ag=gemini, an=codecompanion, ao=opencode)
b → Buffer
c → Code (format, actions, diagnostics, lint)
d → Debug (DAP)
e → Explorer (oil, snacks, blink-tree)
f → File (new, path, chmod)
g → Git (gitsigns, diffview, lazygit)
h → Harpoon
l → LSP global (restart, hints, log, info, mason)
p → Picker (snacks picker)
q → Quit/session
r → Rename
s → Search/replace
u → UI/toggle
w → Window
x → Diagnostics/quickfix (Trouble)
z → Zen
```

## Qué NO hacer al editar este config

- NO añadir `hrsh7th/cmp-nvim-lsp` — fue eliminado (blink.cmp es el stack)
- NO añadir `workspace.library` a lua_ls — lazydev.nvim lo maneja
- NO usar `stevearc/dressing.nvim` con avante — conflicto con snacks ui.select
- NO usar `event = "UIEnter"` para plugins pesados
- NO poner keymaps de plugins en `keymaps.lua` — van en `keys = {}` del spec
- NO usar `require("lazy").load()` para cargar plugins de colorscheme — usar
  `vim.opt.rtp:append(plugin.dir)` en su lugar (lazy.load dispara el auto-config
  del plugin y emite "Lua module not found" si el módulo no matchea el nombre del repo)

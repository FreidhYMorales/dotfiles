# CONTEXT — Referencia de Configuración Neovim

Directorio de referencia técnica para entender, mantener y extender
esta configuración de Neovim. Actualizar cuando se hagan cambios significativos.

## Archivos

| Archivo | Contenido |
|---------|-----------|
| `00-architecture.md` | Árbol de carga, convenciones estrictas, principios de lazy-loading |
| `01-lsp-stack.md` | LSP servers, capabilities, formatters, linters, keymaps LSP |
| `02-theme-system.md` | Night Wolf: variantes, paletas, overrides, integrations |
| `03-plugins-inventory.md` | Todos los plugins con su rol, archivo y keymaps principales |
| `04-keymaps.md` | Mapa completo de keybindings por grupo |
| `05-decisions-log.md` | Log de decisiones técnicas no-obvias y problemas resueltos |

## Resumen rápido

```
Config root: /home/deadlock/Archivos/Configuraciones/nvim/
Plugins:     lua/Deadlock/plugins/*.lua
LSP:         lua/Deadlock/plugins/lsp/{mason,lspconfig}.lua
Core config: lua/Deadlock/config/{lazy,options,keymaps,autocmd}.lua
Theme:       lua/Deadlock/my-theme/
Context:     CONTEXT/  ← estás aquí
```

### Stack tecnológico principal

- **Plugin manager:** `folke/lazy.nvim`
- **UI core:** `folke/snacks.nvim` (terminals, pickers, notifier, dashboard)
- **Completion:** `saghen/blink.cmp` + LuaSnip
- **LSP bridge:** `require("blink.cmp").get_lsp_capabilities()` — NO cmp_nvim_lsp
- **LSP manager:** `mason.nvim` + `mason-lspconfig`
- **Lua types:** `folke/lazydev.nvim` — maneja workspace de lua_ls
- **Formatter:** `stevearc/conform.nvim`
- **Linter:** `mfussenegger/nvim-lint`
- **Treesitter:** `nvim-treesitter` (30+ parsers)
- **Theme:** Night Wolf custom (`lua/Deadlock/my-theme/`) + picker `<leader>uv` con soporte ext plugins
- **Color preview:** `brenoprata10/nvim-highlight-colors` (`render="foreground"`, integrado con blink)
- **Indentación:** Tabs reales, `tabstop=4`, `expandtab=false`

### Reglas que NO se deben violar

1. **Completion bridge:** Solo `require("blink.cmp").get_lsp_capabilities()`
2. **lua_ls workspace:** Delegar a lazydev — no añadir `workspace.library` manual
3. **Terminals:** Solo via `Snacks.terminal.*`
4. **vim.ui:** No usar `dressing.nvim` — conflicto con avante + snacks
5. **cmp-nvim-lsp:** No reinstalar — fue eliminado intencionalmente
6. **FloatBorder doble:** El segundo set en my-theme/init.lua es intencional
7. **Carga de plugins de colorscheme:** Usar `vim.opt.rtp:append(plugin.dir)`, NO `require("lazy").load()` — lazy.load dispara el auto-config y emite warnings en plugins cuyo repo se llama `nvim`

## Cuándo actualizar este directorio

- Al agregar un plugin nuevo: actualizar `03-plugins-inventory.md`
- Al cambiar una decisión arquitectural: agregar entrada en `05-decisions-log.md`
- Al agregar keymaps: actualizar `04-keymaps.md`
- Al cambiar el tema o agregar variantes: actualizar `02-theme-system.md`
- Al cambiar LSP servers/tools: actualizar `01-lsp-stack.md`

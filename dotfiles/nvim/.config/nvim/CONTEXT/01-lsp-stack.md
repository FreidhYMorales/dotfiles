# Stack LSP — Referencia Técnica

## Cadena de dependencias

```
mason.nvim  (lazy=false)
  └─ mason-lspconfig.nvim      ← instala servidores
  └─ mason-tool-installer.nvim ← instala formatters/linters
  └─ nvim-lspconfig            ← provee defaults de cmd/filetypes/root_dir
  └─ saghen/blink.cmp          ← debe estar listo antes del LSP setup

nvim-lspconfig  (event: BufReadPre/BufNewFile)
  └─ saghen/blink.cmp          ← capabilities bridge
  └─ antosha417/nvim-lsp-file-operations
```

## Capabilities — REGLA CRÍTICA

```lua
-- ✅ CORRECTO (blink.cmp stack)
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- ❌ INCORRECTO — NO usar aunque parezca funcionar
local capabilities = require("cmp_nvim_lsp").default_capabilities()
```

`hrsh7th/cmp-nvim-lsp` fue eliminado el 2026-03-12. Si reaparece en
`dependencies` de cualquier plugin de LSP, eliminarlo.

## Servidores LSP configurados

| Servidor | Lenguaje | Notas |
|----------|----------|-------|
| `lua_ls` | Lua | workspace delegado a `lazydev.nvim` — NO añadir `workspace.library` manual |
| `ts_ls` | TypeScript/JS | inlay hints completos (params, tipos, retorno) |
| `html` | HTML | defaults de lspconfig |
| `cssls` | CSS | defaults |
| `tailwindcss` | Tailwind | filetypes extendidos a svelte |
| `gopls` | Go | `staticcheck=true`, `gofumpt=true`, `unusedparams=true`, `hints` activados |
| `pyright` | Python | Solo tipos: `typeCheckingMode="basic"`, `diagnosticMode="workspace"`, `disableOrganizeImports=true` (los imports los ordena ruff) |
| `ruff` | Python | Lint en vivo + code actions (`ruff server`). `hoverProvider` desactivado → el hover lo da pyright |
| `clangd` | C/C++ | `--clang-tidy`, `--header-insertion=iwyu` |
| `bashls` | Shell | filetypes: sh, bash (zsh excluido: falsos positivos) |
| `csharp_ls` | C# | desactivado (requiere .NET SDK, no instalado por mason) |
| `angularls` | Angular | defaults |
| `emmet_ls` | HTML/CSS snippets | filetypes: html, typescriptreact, javascriptreact, css, scss, sass, less, svelte |
| `marksman` | Markdown | defaults |
| `jsonls` | JSON | schemas de `SchemaStore.nvim` + `validate.enable=true`. Formato: prettier (conform) |
| `yamlls` | YAML | schemas de `SchemaStore.nvim` (store interno desactivado: `schemaStore.enable=false`, `url=""`) |
| `qmlls` | QML (Quickshell) | `cmd=/usr/lib/qt6/bin/qmlls` (fuera del PATH). Imports de Quickshell vía el `.qmlls.ini` que genera Quickshell junto a `shell.qml` — requiere que exista (bootstrap lo crea, está gitignoreado). Avisos `uncreatable-type`/`unresolved-type` en `PanelWindow` son falsos positivos de los metadatos de Quickshell |
| `rust_analyzer` | Rust | `check.command="clippy"`, inlay hints |

## lua_ls — configuración mínima (lazydev se encarga del resto)

```lua
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            completion = { callSnippet = "Replace" },
            -- lazydev.nvim ya inyecta:
            --   diagnostics.globals = { "vim" }
            --   workspace.library = { $VIMRUNTIME/lua, config/lua, ... }
            --   + tipos para vim.uv, Snacks, lazy.nvim
        },
    },
})
```

**NO añadir** `diagnostics.globals`, `workspace.library` ni `workspace.checkThirdParty`.
Si hay falsos positivos de `undefined global`, verificar que `lazydev.nvim` está activo:
```
:checkhealth lazydev
```

## Inlay hints — servidores configurados

Los inlay hints se activan/desactivan con `<leader>uh` (buffer) o `<leader>li` (global).

### ts_ls — TypeScript/JavaScript

```lua
settings = {
    typescript = { inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
    }},
    javascript = { inlayHints = { -- misma config ← } },
}
```

### gopls — Go

```lua
hints = {
    assignVariableTypes = true,
    compositeLiteralFields = true,
    compositeLiteralTypes = true,
    constantValues = true,
    functionTypeParameters = true,
    parameterNames = true,
    rangeVariableTypes = true,
}
```

### lua_ls — Lua

Inlay hints deshabilitados (no añadir — lazydev.nvim los gestiona cuando aplica).

## Formatters instalados por mason-tool-installer

| Tool | Lenguajes |
|------|-----------|
| `prettier` | JS/TS/HTML/CSS/JSON/YAML/GraphQL |
| `stylua` | Lua (4-space indent en `.stylua.toml`) |
| `ruff` | Python — conform: `ruff_organize_imports` + `ruff_format` (reemplaza isort + black; `ruff_fix` NO va en format-on-save, los autofixes quedan como code actions) |
| `shfmt` | Shell (4-space) |
| `clang-format` | C/C++ (deshabilitado en conform, solo instalado) |
| `goimports` + `gofumpt` | Go |

## Linters instalados

| Tool | Lenguajes |
|------|-----------|
| `shellcheck` | Shell |
| `biome` | JS/TS |

## Diagnósticos — configuración global

```lua
vim.diagnostic.config({
    signs = { text = { ERROR=" ", WARN=" ", HINT="󰠠 ", INFO=" " } },
    virtual_text = true,
    underline = true,
    update_in_insert = false,  -- ← IMPORTANTE: no redibujar mientras se escribe
    float = { border = "rounded", source = true },
})
```

## Keymaps LSP (buffer-local, via LspAttach)

| Key | Acción |
|-----|--------|
| `gR` | Referencias (snacks picker) |
| `gD` | Declaración (`vim.lsp.buf.declaration`) |
| `gd` | Definición (snacks picker) |
| `gi` | Implementaciones (snacks picker) |
| `gt` | Type definitions (snacks picker) |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename |
| `K` | Hover doc (border=rounded) |
| `<leader>uh` | Toggle inlay hints |
| `<leader>lr` | Restart LSP (`stop_client` + `edit`) — global en keymaps.lua |
| `<C-h>` (insert) | Signature help (border=rounded) |

# Mapa de Keymaps  (actualizado 2026-03-12)

## Convenciones

- `<leader>` = `Space`
- `<localleader>` = `\`
- **Globales:** `lua/Deadlock/config/keymaps.lua` — `local key = vim.keymap.set`
- **Plugin:** `keys = {}` en el spec de lazy.nvim
- **LSP buffer-local:** `LspAttach` autocmd en `lsp/lspconfig.lua`
- **LSP globales:** `lua/Deadlock/config/keymaps.lua` bajo `<leader>l`

## Principios de diseño (refactor 2026-03-12)

1. Una acción = un atajo (sin duplicados)
2. Home row primero (`hjkl`, letras centrales); arrow keys solo para acciones raras
3. Nemotecnia: `c`=code `g`=git `l`=lsp `p`=picker `f`=file `x`=diag
4. Lua nativa: `vim.cmd.quit`, `vim.fn.system`, `snacks.bufdelete`
5. Grupo `<leader>l` activado para todos los keymaps LSP globales

---

## Grupo `<leader>a` — AI Tools

### `<leader>aa` → Avante
| Key | Modo | Acción |
|-----|------|--------|
| `<leader>aa` | n, v | Ask |
| `<leader>aae` | v | Edit |
| `<leader>aar` | n | Refresh |
| `<leader>aat` | n | Toggle |

### `<leader>ac` → Claude Code
| Key | Modo | Acción |
|-----|------|--------|
| `<leader>ac` | n | Toggle terminal |
| `<leader>acf` | n | Focus |
| `<leader>acr` | n | Resume |
| `<leader>acc` | n | Continue |
| `<leader>acm` | n | Select model |
| `<leader>acb` | n | Add buffer |
| `<leader>acs` | v | Send selection / (ft:tree) Add file |
| `<leader>aca` | n | Accept diff |
| `<leader>acd` | n | Deny diff |
| `<leader>ack` | n | Continue recent |
| `<leader>acv` | n | Verbose logging |

### `<leader>ag` → Gemini
| Key | Modo | Acción |
|-----|------|--------|
| `<leader>ag` | n | Toggle terminal |
| `<leader>aG` | v | Send selection |

### `<leader>an` → CodeCompanion
| Key | Modo | Acción |
|-----|------|--------|
| `<leader>an*` | n | Ver plugin spec |

### `<leader>ao` → OpenCode
| Key | Modo | Acción |
|-----|------|--------|
| `<leader>ao`   | n | Toggle |
| `<leader>aos`  | n | Select |
| `<leader>aoi`  | n | Ask |
| `<leader>aoI`  | n | Ask with context |
| `<leader>aob`  | n | Ask about buffer |
| `<leader>aop`  | — | Prefijo prompts |
| `<leader>aope` | n | Explain |
| `<leader>aopf` | n | Fix |
| `<leader>aopd` | n | Diagnose |
| `<leader>aopr` | n | Review |
| `<leader>aopt` | n | Test |
| `<leader>aopo` | n | Optimize |

---

## Grupo `<leader>b` — Buffers

| Key | Modo | Acción | Impl |
|-----|------|--------|------|
| `[b` | n | Buffer anterior | `bprevious` |
| `]b` | n | Buffer siguiente | `bnext` |
| `<S-h>` | n | Buffer anterior | alias de `[b` (home row) |
| `<S-l>` | n | Buffer siguiente | alias de `]b` (home row) |
| `<leader>bd` | n | Delete buffer | `snacks.bufdelete()` |
| `<leader>bD` | n | Force delete buffer | `snacks.bufdelete({ force=true })` |
| `<leader>bo` | n | Delete otros buffers | `snacks.bufdelete.other()` |
| `<leader>bx` | n | Delete (snacks confirm) | definido en snacks.lua |

> `<S-Left>/<S-Right>` eliminados — arrow keys en normal mode = mala ergonomía.
> `<leader>bd` ahora usa snacks (más robusto que `:bd`).

---

## Grupo `<leader>c` — Code

| Key | Modo | Acción | Impl |
|-----|------|--------|------|
| `<leader>ca` | n, v | Code actions (LSP) | `vim.lsp.buf.code_action` (buffer-local) |
| `<leader>cf` | n, v | Format file/range | `conform.format(...)` |
| `<leader>cd` | n | Diagnostics float | `vim.diagnostic.open_float` |
| `<leader>cs` | n | Symbols/outline | aerial (buffer-local via plugin) |
| `<leader>rn` | n | Rename symbol (LSP) | `vim.lsp.buf.rename` (buffer-local) |

> Keymaps buffer-local (`ca`, `cs`, `rn`) se activan en LspAttach.
> `<leader>cf` es el ÚNICO atajo de format — `<leader>mp` fue eliminado.

---

## Grupo `<leader>d` — Debug (DAP)

| Key | Modo | Acción |
|-----|------|--------|
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dB` | n | Breakpoint condicional |
| `<leader>dc` | n | Continue / Start |
| `<leader>dC` | n | Run to cursor |
| `<leader>di` | n | Step into |
| `<leader>do` | n | Step out |
| `<leader>dO` | n | Step over |
| `<leader>dt` | n | Terminate |
| `<leader>dr` | n | Toggle REPL |
| `<leader>dl` | n | Run last |
| `<leader>du` | n | Toggle DAP UI |
| `<leader>dw` | n | Widgets hover |
| `<leader>ds` | n | Session info |
| `<leader>dg` | n | Go to line (no exec) |
| `<leader>dj` | n | Down (call stack) |
| `<leader>dk` | n | Up (call stack) |
| `<leader>dp` | n | Pause |

---

## Grupo `<leader>e` — Explorer

| Key | Acción |
|-----|--------|
| `\\` | Oil (explorador primario — 1 tecla) |
| `<leader>e` | Oil (alias con leader) |
| `<leader>es` | Snacks explorer (sidebar) |
| `<leader>er` | Reveal archivo en blink-tree |
| `<leader>eT` | Toggle blink-tree |
| `<leader>et` | Toggle foco en blink-tree |

---

## Grupo `<leader>f` — File utilities

| Key | Acción | Impl |
|-----|--------|------|
| `<leader>fn` | Nuevo archivo | `vim.cmd.enew` |
| `<leader>fp` | Copiar path al clipboard | `vim.fn.setreg("+", path)` + notify |
| `<leader>fx` | chmod +x | `vim.fn.system("chmod +x " .. shellescape)` |

---

## Grupo `<leader>g` — Git

### Gitsigns (`<leader>gh*` — buffer-local)

| Key | Modo | Acción |
|-----|------|--------|
| `]h` / `[h` | n | Siguiente / anterior hunk |
| `]H` / `[H` | n | Último / primer hunk |
| `<leader>ghs` | n, v | Stage hunk |
| `<leader>ghr` | n, v | Reset hunk |
| `<leader>ghS` | n | Stage buffer |
| `<leader>ghu` | n | Undo stage hunk |
| `<leader>ghR` | n | Reset buffer |
| `<leader>ghp` | n | Preview hunk (float) |
| `<leader>ghP` | n | Preview hunk inline |
| `<leader>ghb` | n | Blame línea (detallado) |
| `<leader>ghB` | n | Blame buffer completo |
| `<leader>ghd` | n | Diff this |
| `<leader>ghD` | n | Diff this ~ |
| `<leader>gtb` | n | Toggle line blame EOL |
| `<leader>gtd` | n | Toggle deleted lines |
| `<leader>gtw` | n | Toggle word diff |
| `<leader>gS`  | n | Stage buffer (global) |
| `<leader>gR`  | n | Reset buffer (global) |
| `ih` | o, x | Text object: hunk |

### Diffview

| Key | Acción |
|-----|--------|
| `<leader>gd` | Diffview open (archivo actual) |
| `<leader>gf` | Historial git del archivo |
| `<leader>gF` | Historial git del repo |

### Lazygit (Snacks)

| Key | Acción |
|-----|--------|
| `<leader>lg` | Lazygit |
| `<leader>gl` | Lazygit log |
| `<leader>gbr` | Cambiar branch (snacks picker) |

---

## Grupo `<leader>h` — Harpoon

| Key | Acción |
|-----|--------|
| `<leader>ha` | Add archivo actual |
| `<leader>hh` | Menú de Harpoon |
| `<leader>1` | Ir al archivo 1 |
| `<leader>2` | Ir al archivo 2 |
| `<leader>3` | Ir al archivo 3 |
| `<leader>4` | Ir al archivo 4 |
| `<leader>5` | Ir al archivo 5 |

---

## Grupo `<leader>l` — LSP (globales)  ← NUEVO

| Key | Modo | Acción | Impl |
|-----|------|--------|------|
| `<leader>lr` | n | Restart LSP | `stop_client` + `edit` |
| `<leader>li` | n | Toggle inlay hints (global) | `vim.lsp.inlay_hint.enable` |
| `<leader>ll` | n | Ver LSP log | `:LspLog` |
| `<leader>lI` | n | Ver LSP info | `:LspInfo` |
| `<leader>lm` | n | Mason | `:Mason` |

> **Keymaps buffer-local (LspAttach):** `gd`, `gD`, `gR`, `gi`, `gt`, `K`,
> `<leader>ca`, `<leader>rn`, `<leader>uh` (inlay hints buffer).

---

## Grupo `<leader>p` — Picker (Snacks)

| Key | Modo | Acción |
|-----|------|--------|
| `<leader>pf` | n | Find files |
| `<leader>pr` | n | Recent files (frecency) |
| `<leader>ps` | n | Grep en proyecto |
| `<leader>pws` | n, x | Grep palabra/selección |
| `<leader>pk` | n | Keymaps |
| `<leader>pc` | n | Archivos de config nvim |
| `<leader>pt` | n | Todos los TODOs |
| `<leader>pT` | n | TODO + FIXME + FORGETNOT |

---

## Grupo `<leader>q` — Session / Quit

| Key | Acción |
|-----|--------|
| `<leader>q` | Quit (`vim.cmd.quit`) |
| `<leader>qa` | Quit all |
| `<leader>Q` | Force quit all |
| `<leader>qs` | Guardar sesión (persistence) |
| `<leader>qS` | Seleccionar sesión |
| `<leader>ql` | Restaurar última sesión |
| `<leader>qd` | Eliminar sesión |

---

## Grupo `<leader>r` — Rename / Restart

| Key | Modo | Acción | Origen |
|-----|------|--------|--------|
| `<leader>rn` | n | Rename símbolo (LSP) | buffer-local LspAttach |
| `<leader>rN` | n | Rename archivo | snacks.rename |

---

## Grupo `<leader>s` — Search & Replace

| Key | Modo | Acción |
|-----|------|--------|
| `<leader>ss` | n | Substitute palabra bajo cursor (global) |
| `<leader>ss` | v | Substitute en selección |
| `<leader>sr` | n | Grug-far (search & replace interactivo) |

---

## Grupo `<leader>u` — UI / Toggles

| Key | Acción |
|-----|--------|
| `<leader>ud` | Toggle diagnósticos (virtual text + underline + signs) |
| `<leader>uf` | Toggle format on save |
| `<leader>uh` | Toggle inlay hints (buffer-local, LspAttach) |
| `<leader>ut` | Toggle treesitter context |
| `<leader>uv` | **Theme variant picker** (flotante, preview live, persiste) |
| `<leader>u` | Undo tree |

---

## Grupo `<leader>v` — View / Help

| Key | Acción |
|-----|--------|
| `<leader>vh` | Help pages (snacks picker) |

---

## Grupo `<leader>w` — Window

| Key | Acción | Notas |
|-----|--------|-------|
| `<leader>-` | Split horizontal | Atajo principal |
| `<leader>\|` | Split vertical | Atajo principal |
| `<leader>we` | Equalizar splits | |
| `<leader>wx` | Cerrar split actual | |
| `<leader>wo` | Cerrar otros splits | |
| `<c-w><space>` | Hydra mode (which-key) | Muestra todos los `<C-w>*` |

> `<leader>wh` y `<leader>wv` eliminados — duplicaban `<leader>-` y `<leader>\|`.

---

## Grupo `<leader>x` — Diagnósticos / Trouble

| Key | Acción |
|-----|--------|
| `<leader>xx` | Toggle Trouble (panel principal) |
| `<leader>xd` | Diagnósticos del documento |
| `<leader>xw` | Diagnósticos del workspace |
| `<leader>xs` | Símbolos (Trouble) |
| `<leader>xq` | Quickfix list |
| `<leader>xl` | Location list |
| `<leader>xt` | TODOs en Trouble |
| `[q` / `]q` | Prev/next item en Trouble o quickfix |

---

## Navegación bracket `[` / `]`

| Key | Acción | Plugin |
|-----|--------|--------|
| `[b` / `]b` | Buffer prev/next | nativo |
| `[d` / `]d` | Diagnóstico prev/next (float) | `vim.diagnostic.goto_*` |
| `[h` / `]h` | Hunk prev/next | gitsigns |
| `[H` / `]H` | Primer/último hunk | gitsigns |
| `[q` / `]q` | Quickfix / Trouble prev/next | trouble.nvim |
| `[t` / `]t` | TODO prev/next | todo-comments |

---

## Navegación de splits / ventanas

| Key | Modo | Acción |
|-----|------|--------|
| `<C-h/j/k/l>` | n, t | Navegar entre splits (también desde terminal) |
| `<C-Up>` | n | Aumentar altura |
| `<C-Down>` | n | Reducir altura |
| `<C-Left>` | n | Reducir ancho |
| `<C-Right>` | n | Aumentar ancho |

---

## Terminal

| Key | Modo | Acción |
|-----|------|--------|
| `<C-/>` | n, t | Toggle terminal (snacks) |
| `<C-h/j/k/l>` | t | Navegar a split (snacks win keys) |
| `<Esc><Esc>` | t | Salir de terminal mode → normal |

---

## Texto / Edición

| Key | Modo | Acción |
|-----|------|--------|
| `<C-s>` | n, i, v | Guardar archivo |
| `<C-d>` / `<C-u>` | n | Scroll + centrar cursor |
| `n` / `N` | n | Resultado de búsqueda + centrar |
| `J` | n | Join lines (preserva cursor) |
| `<M-j>` / `<M-k>` | n, v | Mover línea/selección abajo/arriba |
| `<` / `>` | v | Indentar (mantiene selección) |
| `p` | v | Paste sin perder registro |
| `<leader>/` | n, v | Toggle comentario |

> `J/K` en visual mode para mover líneas eliminados — solo `<M-j/k>` en todos los modos.

---

## Command line

| Key | Acción |
|-----|--------|
| `<C-a>` | Inicio de línea |
| `<C-e>` | Final de línea |
| `<M-b>` | Palabra atrás |
| `<M-f>` | Palabra adelante |

---

## Misc globales

| Key | Acción |
|-----|--------|
| `<leader>n` | Historial de notificaciones |
| `<leader>L` | Lazy (plugin manager) |
| `<leader>z` | Zen mode |
| `<leader>?` | Keymaps buffer-local (which-key) |
| `<leader>pk` | Keymaps globales (snacks picker) |
| `<F1>` | Neovim help (`:help`) |
| `<C-;>` | Toggle `;` al final de línea (blink.nvim) |
| `<M-,>` | Toggle `,` al final de línea (blink.nvim) |
| `\\` | Explorer Oil |
| `Q` | `<nop>` — deshabilitado (Ex mode) |

---

## Grupos which-key (completo)

```
<leader>a    → AI
<leader>aa   → Avante
<leader>ac   → Claude Code    ← toggle + prefijo
<leader>ag   → Gemini         ← toggle + prefijo
<leader>an   → CodeCompanion
<leader>ao   → OpenCode       ← toggle + prefijo
<leader>aop  → Prompts
<leader><tab>→ Tabs
<leader>b    → Buffer
<leader>c    → Code
<leader>d    → Debug
<leader>e    → Explorer
<leader>f    → File
<leader>g    → Git
<leader>gb   → Branches
<leader>gh   → Hunks
<leader>gt   → Toggle (git)
<leader>h    → Harpoon
<leader>l    → LSP             ← NUEVO (lr li ll lI lm)
<leader>p    → Picker
<leader>q    → Quit/Session
<leader>r    → Rename/Restart
<leader>s    → Search/Replace
<leader>u    → UI/Toggle
<leader>v    → View/Help
<leader>w    → Window          ← proxy <C-w> + hydra mode
<leader>x    → Diagnostics/Quickfix
[            → prev
]            → next
g            → goto
gs           → surround
z            → fold
```

## Flash (motion)

| Key | Modo | Acción |
|-----|------|--------|
| `s` | n, x, o | Jump por caracteres |
| `S` | n, x, o | Treesitter jump |
| `r` | o | Remote flash |
| `R` | x, o | Treesitter search |
| `<C-s>` | c | Toggle flash en búsqueda `/` |
| `<C-Space>` | n, o, x | Selección incremental treesitter |

## mini.surround

| Key | Acción |
|-----|--------|
| `gsa` | Add surround |
| `gsd` | Delete surround |
| `gsr` | Replace surround |
| `gsf` | Find surround (adelante) |
| `gsh` | Highlight surround |

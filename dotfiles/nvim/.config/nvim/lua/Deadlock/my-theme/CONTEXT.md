# my-theme — Contexto de arquitectura

Puerto Neovim del tema VS Code **Night Wolf**. La fuente original vive en
`example/source/` (JavaScript + chroma-js). Todo valor hexadecimal en este
documento es el valor final resuelto (sin mutaciones chroma).

---

## Estructura de archivos

```
my-theme/
├── init.lua              # Punto de entrada público. theme.setup() + theme.colorscheme()
│                         # Contiene TODOS los grupos de highlight (base, TS, LSP, lenguajes)
├── colorscheme.lua       # Paleta de colores + tabla de variantes. Devuelve una tabla plana.
├── config.lua            # Defaults: variant, italics.*, overrides
├── utils.lua             # M.mix(fg, bg, alpha) · M.shade(color, value, base)
├── types.lua             # Anotaciones LuaLS (@class, @alias)
└── integrations/
    ├── avante.lua        # Avante AI sidebar
    ├── bufferline.lua    # nvim-bufferline (recibe config como argumento)
    ├── cmp.lua           # nvim-cmp + Pmenu base
    ├── lsp.lua           # LspInfo, LspSignature, LspReferences, LspInlayHint
    └── noice.lua         # noice.nvim borders
```

---

## Paleta completa — colorscheme.lua

### Colores sintaxis (compartidos por todas las variantes dark)

| Nombre Lua           | Hex       | Origen JS            | Rol semántico                                   |
|----------------------|-----------|----------------------|-------------------------------------------------|
| `syntaxFunction`     | `#00DCDC` | `syntaxCyan`         | funciones, métodos, cyan                        |
| `syntaxKeyword`      | `#9696FF` | `syntaxViolet`       | keywords (var/let/for/while), specialWordB      |
| `specialKeyword`     | `#DC8CFF` | `syntaxPurple`       | if/else/switch/loops, types, specialWordC       |
| `lightRed`           | `#FF7878` | `syntaxRed`          | operadores, booleans, tags HTML, contrastText   |
| `warningEmphasis`    | `#FFB482` | `syntaxOrange`       | números, self/this en OOP, variableInstance     |
| `warningText`        | `#FFDC96` | `syntaxYellow`       | variables, parámetros, punctuation.brackets     |
| `stringText`         | `#AAE682` | `syntaxGreen`        | strings, success states                         |
| `linkText`           | `#00B1FF` | `syntaxBlue`         | import/export/var/let/const, links, specialWordA|
| `syntaxLightBlue`    | `#86E0F4` | `syntaxLightBlue`    | TS interfaces/types, CSS variables, MD links    |
| `syntaxBeige`        | `#DBD4BA` | `syntaxBeige`        | regex, inline code markdown                     |
| `syntaxMagenta`      | `#FF50FF` | `syntaxMagenta`      | terminal ANSI magenta                           |
| `commentText`        | `#647882` | `comment`            | comentarios, inlay hints, code lens             |
| `syntaxError`        | `#F05050` | `danger`             | errores, diagnósticos                           |
| `errorText`          | `#F05050` | `danger`             | alias de syntaxError                            |
| `successText`        | `#AAE682` | `syntaxGreen`        | diff add, hints, success (mismo que stringText) |
| `property`           | `#FFDC96` | `syntaxYellow`       | fields/properties de objetos (= warningText)    |
| `syntaxOperator`     | `#C8C8C8` | `text`               | delimitadores, puntuación muda                  |

### Colores de texto / chrome (comunes)

| Nombre Lua              | Hex       | Rol                                       |
|-------------------------|-----------|-------------------------------------------|
| `mainText`              | `#C8C8C8` | texto principal (varía por variante)      |
| `emphasisText`          | `#FFFFFF` | texto enfatizado, bordes activos          |
| `inactiveText`          | `#787878` | texto inactivo (varía por variante)       |
| `disabledText`          | `#969696` | texto deshabilitado (varía por variante)  |
| `lineNumberText`        | `#969696` | números de línea (varía por variante)     |
| `standardWhite`         | `#FFFFFF` | blanco puro                               |
| `standardBlack`         | `#000000` | negro puro                                |

### Colores de chrome / UI (dependen de la variante activa)

| Nombre Lua                | Rol en Neovim                              |
|---------------------------|--------------------------------------------|
| `editorBackground`        | `Normal` bg                                |
| `sidebarBackground`       | `StatusLineNC`, `TabLine`, sidebar bg      |
| `popupBackground`         | `CursorLine`, `Folded`                     |
| `floatingWindowBackground`| `NormalFloat`, `FloatBorder` bg            |
| `menuOptionBackground`    | `PmenuSel`, `LspReference*`, `WildMenu`    |
| `windowBorder`            | `VertSplit`, `WinSeparator`                |
| `focusedBorder`           | uso futuro / override                      |
| `emphasizedBorder`        | uso futuro / override                      |

---

## Sistema de variantes

Definidas en `colorscheme.lua`, seleccionadas por `config.variant`:

| Variante       | `editorBackground` | Origen JS      | Notas                                   |
|----------------|--------------------|----------------|-----------------------------------------|
| `"default"`    | `"none"`           | black          | Transparente. Usa escala principal black|
| `"black"`      | `#000000`          | black          | Negro puro                              |
| `"dark"`       | `#1B1B1B`          | dark-gray      | mainText = `#CECECE`                    |
| `"darker"`     | `#252525`          | gray           | mainText = `#CECECE`                    |
| `"dark_blue"`  | `#101E2C`          | dark-blue      | mainText = `#BDD2E7`, inactiveText azul |
| `"light"`      | `#FFFFFF`          | —              | Paleta light separada                   |
| `"light_transparent"` | `"none"`  | —              | Transparente light                      |

Cada variante puede sobreescribir `mainText`, `inactiveText`, `lineNumberText`,
`disabledText`. La resolución final es:

```
syntax (dark|light) → merge variant overrides → colorscheme table
```

`is_transparent = true` activa `set_background_transparent()` en `init.lua`
que elimina el `bg` de `Normal`, `NormalFloat`, `Pmenu`, `FloatBorder`, etc.

---

## Cómo añadir una integración nueva

### 1. Crear `integrations/<plugin>.lua`

```lua
local colorscheme = require("Deadlock.my-theme.colorscheme")
-- local utils = require("Deadlock.my-theme.utils")  -- si necesitas mix/shade

local M = {}

function M.highlights()
  return {
    PluginGroup = { fg = colorscheme.syntaxFunction, bg = colorscheme.floatingWindowBackground },
    -- ...
  }
end

return M
```

### 2. Registrar en `init.lua`

Hay dos lugares:

**a) Top-level require (líneas 7-11):**
```lua
local miplugin = require("Deadlock.my-theme.integrations.miplugin")
```

**b) Limpiar el cache en `theme.setup()` (líneas 383-395):**
```lua
package.loaded["Deadlock.my-theme.integrations.miplugin"] = nil
-- ...
miplugin = require("Deadlock.my-theme.integrations.miplugin")
```

**c) Merge en `set_groups()` (líneas 436-440):**
```lua
groups = vim.tbl_extend("force", groups, miplugin.highlights())
```

### Excepción: bufferline

`bufferline.highlights()` recibe `config` como argumento (para `italics.bufferline`).
Se expone en `theme.bufferline.highlights` para que el usuario lo pase a bufferline
en su setup. No se aplica vía `nvim_set_hl`.

---

## Reglas de color por rol semántico

Al mapear highlight groups de un plugin nuevo, usar estas asociaciones:

| Situación                              | Color a usar          |
|----------------------------------------|-----------------------|
| Fondo flotante / popup                 | `floatingWindowBackground` |
| Borde de ventana flotante              | `emphasisText` fg (siempre blanco) |
| Borde de ventana normal                | `windowBorder`        |
| Item seleccionado en menú              | `menuOptionBackground` bg + `emphasisText` fg |
| Match / texto encontrado               | `linkText` bold       |
| Error / danger                         | `syntaxError`         |
| Advertencia                            | `warningEmphasis`     |
| Info                                   | `syntaxFunction` (cyan) |
| Hint / success                         | `successText` (= `stringText`, verde) |
| Texto inactivo / dimmed                | `inactiveText`        |
| Comentario / secondary text            | `commentText`         |
| Texto de función / acción principal    | `syntaxFunction`      |
| Referencia a símbolo (read/write)      | `menuOptionBackground` bg |
| Diff add                               | `successText`         |
| Diff delete                            | `syntaxError`         |
| Diff change                            | `syntaxFunction`      |

Para fondos semitransparentes usar `utils.shade(color, alpha, base)` o
`utils.mix(fg, bg, alpha)`. Ejemplos en `avante.lua`.

---

## Grupos de highlight implementados en init.lua

### Base Neovim
`Normal`, `LineNr`, `CursorLine`, `SignColumn`, `Folded`, `StatusLine`,
`StatusLineNC`, `TabLine`, `TabLineSel`, `VertSplit`, `WinSeparator`,
`FloatBorder`, `NormalFloat`, `Pmenu` (via cmp.lua), `Search`, `IncSearch`,
`Visual`, `DiffAdd/Change/Delete/Text`, `SpellBad/Cap/Local/Rare`, `Title`,
`MatchParen`, `EndOfBuffer`, + grupos de syntaxis clásica (`Keyword`, `String`,
`Function`, `Comment`, etc.)

### Diagnósticos
`DiagnosticError/Warn/Info/Hint`, `DiagnosticVirtualText*`, `DiagnosticUnderline*`

### Tree-Sitter
Todos los `@text.*`, `@markup.*`, `@comment.*`, `@punctuation.*`,
`@string.*`, `@function.*`, `@method.*`, `@variable.*`, `@type.*`,
`@keyword.*`, `@tag.*`, `@operator`, `@number`, `@boolean`, `@constant.*`,
`@label`, `@namespace`, `@module`, `@field`, `@property`, `@parameter`,
`@attribute`, `@diff.*`, `@symbol`, `RainbowDelimiter*`

### LSP semantic tokens
`@lsp.type.*` (namespace, type, class, enum, enumMember, interface, struct,
parameter, property, function, method, macro, decorator, variable, keyword,
regexp) + `@lsp.typemod.*`

### Language overrides
- **Lua**: funciones/métodos → `mainText` (sin color, como en VS Code)
- **JS/TS/TSX/JSX**: `@variable.builtin` → `lightRed` (this = rojo)
- **Go**: keywords → `linkText` italic, types → `warningText`, builtins → `lightRed`
- **CSS/SCSS**: propiedad → `syntaxFunction`, tag → `lightRed`, clase → `warningText`,
  variable → `syntaxLightBlue`, attr → `stringText`, pseudo-class → `specialKeyword`
- **JSON**: labels → `property`
- **Markdown**: headings → `syntaxKeyword` bold, quotes → `stringText` italic,
  URL → `syntaxLightBlue`, listas → `warningText`, raw/code → `syntaxBeige`,
  separadores → `warningEmphasis`

### Plugins integrados
| Plugin      | Archivo                      | Patrón de uso                        |
|-------------|------------------------------|--------------------------------------|
| avante.nvim | `integrations/avante.lua`    | `M.highlights()` → merge en init    |
| bufferline  | `integrations/bufferline.lua`| `M.highlights(config)` → expuesto en `theme.bufferline.highlights` |
| nvim-cmp    | `integrations/cmp.lua`       | `M.highlights()` → merge en init    |
| LSP         | `integrations/lsp.lua`       | `M.highlights()` → merge en init    |
| noice.nvim  | `integrations/noice.lua`     | `M.highlights()` → merge en init    |

---

## Limitaciones conocidas vs VS Code

| Diferencia                        | Razón                                          |
|-----------------------------------|------------------------------------------------|
| Operadores `&&`/`\|\|` no son púrpura | Tree-sitter `@operator` no divide por tipo  |
| `this` y `self` comparten grupo   | `@variable.builtin` es genérico (en JS/TS se arregla con override por lenguaje) |
| Decoradores TS no tienen color específico | Mapean a `@label` (lightRed)           |
| JS labels (`label:`) son `pinkPastel` en VS Code | No implementado (color de test) |

---

## Fuente de referencia

`example/source/dark.js` — 2216 líneas. Contiene:
- `themeColors`: colores del editor/UI de VS Code (líneas 1-809)
- `normalize`: reset de fontStyle para evitar herencia (línea 811)
- `general`: reglas genéricas multi-lenguaje (línea 917)
- `specialWords`: instancias OOP, meta selectors (línea 1236)
- `comments`: comentarios y JSDoc (línea 1302)
- `styleSheets`: CSS/SCSS/Sass/Less (línea 1360)
- `javascript`: JS/TS específico (línea 1677)
- `markdown`: Markdown (línea 1780)
- `go`: Go (línea 1870)
- `python`: Python (línea 1926)
- `html`: HTML/Vue/Svelte (línea 1939)
- `json`: JSON (línea 2006)
- `php`: PHP (línea 2016)

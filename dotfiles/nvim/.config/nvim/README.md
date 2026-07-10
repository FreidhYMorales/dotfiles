# Configuración de Neovim — Deadlock

Configuración personal de Neovim orientada a rendimiento, flujo de trabajo moderno
y coherencia visual total con el tema **Night Wolf** en Hyprland/Wayland.

---

## Índice

1. [Requisitos](#requisitos)
2. [Instalación](#instalación)
3. [Estructura del proyecto](#estructura-del-proyecto)
4. [Tema Night Wolf](#tema-night-wolf)
5. [Plugins por categoría](#plugins-por-categoría)
    - [UI Central — Snacks](#ui-central--snacks)
    - [Completion — blink.cmp](#completion--blinkcmp)
    - [LSP](#lsp)
    - [Formatters y Linters](#formatters-y-linters)
    - [Treesitter](#treesitter)
    - [Git](#git)
    - [Navegación](#navegación)
    - [Herramientas de código](#herramientas-de-código)
    - [Herramientas AI](#herramientas-ai)
    - [Edición de texto](#edición-de-texto)
    - [Debugger (DAP)](#debugger-dap)
6. [Keymaps](#keymaps)
7. [Personalización](#personalización)
8. [Solución de problemas](#solución-de-problemas)

---

## Requisitos

| Dependencia | Versión mínima | Instalación en Arch                                 |
| ----------- | -------------- | --------------------------------------------------- |
| Neovim      | ≥ 0.11         | `pacman -S neovim`                                  |
| Git         | cualquiera     | `pacman -S git`                                     |
| Nerd Font   | cualquiera     | p.ej. `JetBrainsMono Nerd Font`                     |
| ripgrep     | cualquiera     | `pacman -S ripgrep`                                 |
| fd          | cualquiera     | `pacman -S fd`                                      |
| Node.js     | ≥ 18           | `pacman -S nodejs npm`                              |
| Go          | ≥ 1.21         | `pacman -S go` (para gopls)                         |
| Python      | ≥ 3.10         | `pacman -S python`                                  |
| Cargo/Rust  | ≥ 1.70         | `pacman -S rust` (para blink.nvim)                  |
| lazygit     | cualquiera     | `pacman -S lazygit`                                 |
| Gemini CLI  | —              | `npm install -g @google/gemini-cli`                 |
| Claude Code | —              | `npm install -g @anthropic-ai/claude-code`          |
| imagemagick | —              | `pacman -S imagemagick` (para imágenes en Markdown) |

---

## Instalación

```bash
# Respalda tu config existente si tienes una
mv ~/.config/nvim ~/.config/nvim.bak

# Crea el symlink o copia la config
ln -s ~/Archivos/Configuraciones/nvim ~/.config/nvim

# Abre Neovim — lazy.nvim instalará todo automáticamente
nvim
```

Al primer inicio, `lazy.nvim` descarga e instala todos los plugins.
`mason.nvim` instalará los LSP servers y herramientas al abrir `:Mason`.

Para instalar los LSP servers automáticamente:

```
:MasonInstall lua-language-server typescript-language-server pyright gopls ...
```

O simplemente abre cualquier archivo del lenguaje correspondiente y sigue
las sugerencias de Mason.

---

## Estructura del proyecto

```
nvim/
├── init.lua                    ← Entrada: carga el tema, luego todo lo demás
├── README.md                   ← Esta documentación
├── CLAUDE.md                   ← Contexto de proyecto para Claude Code (leído automáticamente)
├── CONTEXT/                    ← Referencia técnica interna
├── lazy-lock.json              ← Versiones exactas de plugins (commitear esto)
├── spell/                      ← Diccionarios de spell check (en + es)
└── lua/
    └── Deadlock/
        ├── config/
        │   ├── init.lua        ← Loader de módulos de config
        │   ├── lazy.lua        ← Bootstrap y setup de lazy.nvim
        │   ├── options.lua     ← Opciones de Neovim (vim.opt)
        │   ├── keymaps.lua     ← Keymaps globales
        │   └── autocmd.lua     ← Autocommands globales
        ├── plugins/            ← Un archivo por plugin (specs de lazy.nvim)
        │   └── lsp/
        │       ├── mason.lua   ← Gestión de LSP servers
        │       └── lspconfig.lua ← Configuración de servidores
        └── my-theme/           ← Tema Night Wolf personalizado
            ├── init.lua
            ├── colorscheme.lua
            └── integrations/
```

---

## Tema Night Wolf

Tema visual completamente personalizado basado en el tema **Night Wolf** de VSCode,
reimplementado para Neovim con soporte de más de 1000 highlight groups.

### Variantes disponibles

| Variante            | Fondo        | Efecto                                   |
| ------------------- | ------------ | ---------------------------------------- |
| `default`           | Transparente | Usa el fondo de tu terminal/compositor   |
| `black`             | `#000000`    | Negro puro                               |
| `dark`              | `#1b1b1b`    | Gris oscuro                              |
| `darker`            | `#252525`    | Gris medio                               |
| `dark_blue`         | `#101e2c`    | Azul oscuro — ideal con wallpapers fríos |
| `light`             | `#ffffff`    | Modo claro                               |
| `light_transparent` | Transparente | Modo claro con fondo de terminal         |
| `terminal`          | Dinámica     | Colores leídos desde caelestia (`~/.local/state/caelestia/sequences.txt`); se sincroniza con el colorscheme del compositor. Fallback a `default` si el archivo no existe |

### Cambiar variante

Usa el picker interactivo con preview live:

```
<leader>uv   Abrir Theme Picker
```

El picker muestra las variantes de Night Wolf y los colorschemes de plugins
instalados (ej. catppuccin, tokyonight). Navegar aplica el tema en tiempo real;
`<CR>` confirma y persiste la selección, `<Esc>` revierte.

La selección se guarda en `~/.local/share/nvim/my-theme-variant` y se restaura
automáticamente al siguiente inicio.

Para cambiar opciones de italics u overrides, edita `init.lua` en la raíz:

```lua
theme.setup({
    variant = "dark_blue",  -- solo se usa si no hay nada guardado en disco
    italics = {
        comments  = true,
        keywords  = true,
        functions = false,
        strings   = false,
        variables = false,
    },
})
```

### Overrides personalizados

Para añadir o sobreescribir highlight groups sin tocar los archivos del tema:

```lua
theme.setup({
    variant = "default",
    overrides = function()
        return {
            -- ejemplo: hacer Normal con fondo completamente negro
            Normal = { bg = "#000000" },
            -- ejemplo: comentarios en verde
            Comment = { fg = "#00ff00", italic = true },
        }
    end,
})
```

### Colores principales (Dark)

| Color         | Hex       | Uso                                     |
| ------------- | --------- | --------------------------------------- |
| Texto         | `#c8c8c8` | Texto normal                            |
| Funciones     | `#00dcdc` | Funciones, métodos (cyan)               |
| Keywords      | `#9696ff` | Palabras clave (violet)                 |
| Tipos/if/else | `#dc8cff` | Tipos y condicionales (purple)          |
| Constantes    | `#ff7878` | Constantes, booleanos, operadores (red) |
| Variables     | `#ffdc96` | Variables, parámetros (yellow)          |
| Strings       | `#aae682` | Strings (green)                         |
| Import/var    | `#00b1ff` | import/export, var/let/const (blue)     |
| Números       | `#ffb482` | Números literales (orange)              |
| Comentarios   | `#647882` | Comentarios                             |

---

## Plugins por categoría

### UI Central — Snacks

`folke/snacks.nvim` es el núcleo de la interfaz. Provee múltiples subsistemas:

#### Picker (buscador de archivos y más)

```
<leader>pf   Buscar archivos en el proyecto
<leader>pr   Archivos recientes (con ranking por frecuencia)
<leader>ps   Buscar texto en el proyecto (grep)
<leader>pws  Buscar la palabra bajo el cursor
<leader>pk   Ver todos los keymaps disponibles
<leader>pc   Buscar en los archivos de config de Neovim
<leader>pt   Ver todos los TODO/FIXME/HACK del proyecto
<leader>pT   Solo TODO, FIXME y FORGETNOT
<leader>vh   Buscar en la ayuda de Neovim
<leader>gbr  Cambiar de branch de git
```

El picker usa **frecency** — los archivos que abres más seguido y más
recientemente aparecen primero.

#### Lazygit integrado

```
<leader>lg   Abrir Lazygit
<leader>gl   Ver log de git con Lazygit
```

#### Notificaciones

```
<leader>n    Ver historial de notificaciones
```

#### Theme Picker

```
<leader>uv   Abrir selector de variante / colorscheme externo
```

Preview live al navegar. `●` indica el tema guardado, `▶` el activo.
Ver sección [Tema Night Wolf](#tema-night-wolf) para más detalles.

---

#### Explorer (explorador secundario)

```
<leader>es   Abrir explorador lateral de Snacks
```

#### Terminales

Todos los terminales de AI usan Snacks como backend, lo que permite
mostrarlos/ocultarlos sin perder el estado de la sesión.

```
<C-/>   Toggle terminal flotante
```

---

### Completion — blink.cmp

Motor de autocompletado con soporte de snippets (LuaSnip).

| Tecla             | Acción                                      |
| ----------------- | ------------------------------------------- |
| `<C-Space>`       | Mostrar/ocultar sugerencias                 |
| `<C-j>` / `<C-n>` | Siguiente sugerencia                        |
| `<C-k>` / `<C-p>` | Sugerencia anterior                         |
| `<CR>` / `<C-y>`  | Aceptar sugerencia                          |
| `<Tab>`           | Avanzar en snippet / siguiente sugerencia   |
| `<S-Tab>`         | Retroceder en snippet / sugerencia anterior |
| `<C-e>`           | Cerrar menú de completion                   |
| `<C-b>` / `<C-f>` | Scroll en documentación                     |
| `<C-d>`           | Ocultar documentación                       |

**Fuentes activas:** LSP, rutas de archivos, snippets, buffer, Lua API
(lazydev), spell (solo en markdown/text).

**Ghost text:** Activado — muestra una preview tenue de la sugerencia más
probable mientras escribes.

**Color swatches:** El ícono de kind en el menú de completion muestra un swatch
del color real para items de tipo color (CSS, Tailwind) via `nvim-highlight-colors`.

---

### LSP

Gestión de Language Servers con `mason.nvim` (instalador) +
`nvim-lspconfig` (configuración).

#### Servidores instalados

| Lenguaje      | Servidor      | Características extra               |
| ------------- | ------------- | ----------------------------------- |
| Lua           | `lua_ls`      | Tipos para Neovim API via lazydev   |
| TypeScript/JS | `ts_ls`       | Completions de módulos, inlay hints |
| HTML          | `html`        | —                                   |
| CSS           | `cssls`       | —                                   |
| Tailwind      | `tailwindcss` | Preview de colores en completion    |
| Go            | `gopls`       | staticcheck, gofumpt, inlay hints   |
| Python        | `pyright`     | Type checking básico                |
| C/C++         | `clangd`      | clang-tidy, IWYU, clang-format      |
| Shell         | `bashls`      | sh, bash, zsh                       |
| C#            | `csharp_ls`   | —                                   |
| Angular       | `angularls`   | —                                   |
| Emmet         | `emmet_ls`    | Snippets HTML/CSS en jsx/tsx/svelte |
| Markdown      | `marksman`    | —                                   |

#### Keymaps LSP — buffer-local (activos al abrir un archivo con LSP)

```
gd           Ir a definición
gD           Ir a declaración
gR           Ver referencias
gi           Ver implementaciones
gt           Ver definición de tipo
K            Ver documentación del símbolo bajo el cursor
<leader>ca   Ver code actions (n y visual)
<leader>rn   Renombrar símbolo
<leader>uh   Toggle inlay hints (buffer)
<C-h>        Signature help (en modo inserción)
```

#### Keymaps LSP — globales (`<leader>l`)

```
<leader>lr   Reiniciar LSP del buffer actual
<leader>li   Toggle inlay hints (global, todos los buffers)
<leader>ll   Ver log del LSP
<leader>lI   Ver info del LSP
<leader>lm   Abrir Mason
```

#### Diagnósticos

```
<leader>cd   Ver diagnóstico de la línea actual en float
<leader>ud   Toggle visibilidad de diagnósticos
]d / [d      Siguiente / anterior diagnóstico (con float)
```

---

### Formatters y Linters

#### Format on save

El formateo automático se activa al guardar. Para desactivarlo:

```
<leader>uf   Toggle format on save (global)
<leader>cf   Formatear manualmente el archivo o selección visual
```

#### Formatters por lenguaje

| Lenguaje              | Formatter         |
| --------------------- | ----------------- |
| JS / TS / JSX / TSX   | biome             |
| CSS                   | biome             |
| HTML / Svelte         | prettier          |
| JSON / YAML / GraphQL | prettier          |
| Lua                   | stylua            |
| Python                | isort + black     |
| Shell (sh/bash/zsh)   | shfmt             |
| C / C++ / C#          | clang-format      |
| Go                    | gofmt + goimports |
| Markdown              | prettier          |

> C y C++ tienen format on save **desactivado** por defecto — se formatea
> manualmente con `<leader>cf`.

#### Linters activos

| Lenguaje | Linter     |
| -------- | ---------- |
| JS / TS  | biome      |
| Python   | pylint     |
| Shell    | shellcheck |
| C / C++  | cpplint    |

Los diagnósticos de linters aparecen en el sign column y con virtual text,
igual que los del LSP.

```
<leader>cl   Lintear el archivo actual manualmente
```

---

### Treesitter

Parsing y highlighting de sintaxis de alta precisión para 30+ lenguajes:
Lua, JavaScript, TypeScript, TSX, HTML, CSS, SCSS, JSON, YAML, GraphQL,
Svelte, Go, Python, C, C++, C#, Bash, Markdown, Vim, Regex, Diff, Git, Yuck.

**Características activas:**

- Syntax highlighting preciso por AST
- **Contexto sticky** en la parte superior del buffer (`<leader>ut` para toggle)
- **Rainbow delimiters** — paréntesis y llaves en colores del tema
- Autocierre de tags HTML (`nvim-ts-autotag`)
- Comentarios contextuales según el lenguaje dentro del archivo

---

### Git

#### Gitsigns — cambios en el buffer

Muestra cambios en el sign column y permite operar sobre hunks:

```
]h / [h      Siguiente / anterior hunk
]H / [H      Último / primer hunk
<leader>ghs  Stage hunk (n y visual)
<leader>ghr  Reset hunk (n y visual)
<leader>ghS  Stage buffer completo
<leader>ghu  Deshacer stage de hunk
<leader>ghR  Reset buffer completo
<leader>ghp  Preview hunk en float
<leader>ghP  Preview hunk inline
<leader>ghb  Blame de la línea actual (detallado)
<leader>ghB  Blame del archivo completo
<leader>gtb  Toggle blame en tiempo real (al final de línea)
<leader>ghd  Diff del archivo actual
<leader>gtd  Toggle vista de líneas eliminadas
<leader>gtw  Toggle word diff
ih           Text object: seleccionar hunk (en visual y operator)
```

#### Diffview — comparación visual

```
<leader>gd   Abrir diff del archivo actual
<leader>gf   Historial de git del archivo actual
<leader>gF   Historial de git completo del repo
```

#### Lazygit (via Snacks)

```
<leader>lg   Abrir Lazygit
<leader>gl   Ver log de git
<leader>gbr  Cambiar de branch
```

---

### Navegación

#### Oil — explorador de archivos

El explorador primario. Funciona como un buffer de texto — editas
nombres de archivos, carpetas, permisos, etc.

```
\   o   <leader>e   Abrir Oil en el directorio del archivo actual
.                   Toggle archivos ocultos
g?                  Ver ayuda de Oil
-                   Subir al directorio padre
<CR>                Entrar al directorio / abrir archivo
<C-s>               Abrir en split vertical
<C-h>               Abrir en split horizontal
```

#### Harpoon — archivos frecuentes

Bookmarks de archivos con acceso inmediato:

```
<leader>ha   Agregar archivo actual a Harpoon
<leader>hh   Abrir menú de Harpoon
<leader>1    Ir al archivo 1 de Harpoon
<leader>2    Ir al archivo 2
<leader>3    Ir al archivo 3
<leader>4    Ir al archivo 4
<leader>5    Ir al archivo 5
```

#### Flash — saltos rápidos

```
s            Salto por caracteres (normal/visual/operator)
S            Treesitter-aware jump
r            Remote jump (operator mode)
R            Selección incremental con treesitter
<C-s>        (en búsqueda /) Toggle flash search
```

#### Blink Tree

```
<leader>eT   Toggle árbol de archivos
<leader>et   Toggle foco en el árbol
<leader>er   Revelar el archivo actual en el árbol
```

#### Splits y ventanas

```
<C-h/j/k/l>           Navegar entre splits
<leader>-              Split horizontal
<leader>|              Split vertical
<leader>we             Equalizar tamaño de splits
<leader>sm             Maximizar/restaurar split actual
<C-Up/Down/Left/Right> Redimensionar split
```

---

### Herramientas de código

#### Aerial — outline/símbolos

Vista de la estructura del archivo (funciones, clases, métodos):

```
<leader>cs   Toggle panel de símbolos
```

Dentro del panel: `<CR>` para ir al símbolo, `<C-j/k>` para navegar.

#### Trouble — diagnósticos y listas

```
<leader>xx   Toggle panel de Trouble
<leader>xd   Diagnósticos del documento actual
<leader>xw   Diagnósticos del workspace
<leader>xq   Quickfix list
<leader>xl   Location list
<leader>xt   TODOs en Trouble
```

#### Todo Comments

Resalta y permite navegar por comentarios especiales:

```
TODO      Tarea pendiente
FIXME     Bug conocido
HACK      Solución temporal
WARN      Advertencia
PERF      Optimización necesaria
NOTE      Nota informativa
TEST      Test pendiente
FORGETNOT Recordatorio importante (custom)
```

```
<leader>pt   Ver todos los TODOs (snacks picker)
<leader>pT   Solo TODO, FIXME y FORGETNOT
]t / [t      Siguiente / anterior TODO
```

#### Undo Tree

Visualiza el árbol completo de historial de cambios:

```
<leader>u    Toggle Undo Tree
```

#### Grug-Far — Search & Replace global

Reemplazo interactivo con ripgrep con previsualización en tiempo real:

```
<leader>sr   Abrir Grug-Far
```

Dentro de Grug-Far puedes filtrar por archivo, tipo, y ver todos los
matches antes de aplicar el reemplazo.

#### nvim-ufo — Folding avanzado

Folding basado en treesitter/LSP con conteo de líneas ocultas:

```
zR   Abrir todos los folds
zM   Cerrar todos los folds
za   Toggle fold bajo el cursor
```

---

### Herramientas AI

Seis asistentes de IA integrados con roles diferenciados — cada uno tiene su
propio namespace de keymaps bajo `<leader>a`:

| Herramienta   | Prefijo      | Rol principal                                                          |
| ------------- | ------------ | ---------------------------------------------------------------------- |
| Avante        | `<leader>aa` | Diff visual interactivo — propone cambios en el buffer actual          |
| Claude Code   | `<leader>ac` | Agente autónomo — escribe archivos, ejecuta comandos, opera en el repo |
| CodeCompanion | `<leader>an` | Chat largo + inline assistant + MCP tools                              |
| OpenCode      | `<leader>ao` | Agente multi-modelo con prompts predefinidos                           |
| Gemini        | `<leader>ag` | CLI conversacional de Google                                           |
| Copilot       | `<M-]>`      | Sugerencia inline bajo demanda (insert mode)                           |

#### Avante (`<leader>aa`) — Diff visual con Claude

Panel lateral con chat contextual, diff visual y edición inline. Las respuestas
de Claude se renderizan con Markdown completo en el panel.

```
<leader>aa   Preguntar / iniciar chat (n y visual)
<leader>aae  Editar selección con Avante (visual)
<leader>aar  Refrescar respuesta
<leader>aat  Toggle panel
```

Modelo: Claude Sonnet 4. `max_tokens = 8096`.
System prompt calibrado para Ingeniería de Software (respuestas técnicas directas).

#### Claude Code (`<leader>ac`) — Agente autónomo

Terminal de Claude Code CLI integrado como panel lateral izquierdo (30% del ancho).
Puede escribir archivos, ejecutar comandos, leer el repo entero y hacer commits.

```
<leader>ac   Toggle terminal de Claude Code
<leader>acf  Focus en el terminal
<leader>acr  Resume sesión anterior
<leader>acc  Continue
<leader>acm  Seleccionar modelo
<leader>acb  Agregar buffer actual al contexto
<leader>acs  Enviar selección / (en árbol) agregar archivo
<leader>aca  Aceptar diff sugerido
<leader>acd  Rechazar diff
<leader>ack  Continuar sesión reciente
<leader>acv  Verbose logging
```

> Lee automáticamente `CLAUDE.md` en la raíz del proyecto para entender
> las convenciones del stack sin necesidad de explicarlo en cada sesión.

#### CodeCompanion (`<leader>an`) — Chat largo + MCP

Chat de larga conversación, inline assistant y extensiones MCP (mcphub).

```
<leader>an   Toggle chat
<leader>ana  Actions menu
<leader>anc  Nueva sesión de chat
<leader>ans  Enviar selección al chat (visual)
<leader>ani  Inline assistant (n y visual)
<leader>anm  Generar comando de shell
```

#### OpenCode (`<leader>ao`) — Agente con prompts

```
<leader>ao   Toggle OpenCode
<leader>aoi  Preguntar
<leader>aoI  Preguntar con contexto del buffer
<leader>aob  Preguntar sobre el buffer actual
<leader>aope Explicar código
<leader>aopf Arreglar código
<leader>aopd Diagnosticar problema
<leader>aopr Revisar código
<leader>aopt Generar tests
<leader>aopo Optimizar código
```

#### Gemini (`<leader>ag`) — Google Gemini CLI

Terminal de Gemini CLI como panel lateral. Mantiene la sesión activa entre toggles.

```
<leader>ag   Toggle terminal de Gemini
<leader>aG   Enviar selección visual a Gemini (visual)
```

#### GitHub Copilot — Sugerencias inline bajo demanda

Copilot está configurado en **modo manual** para no competir visualmente con
el ghost text de blink.cmp. Se activa explícitamente:

```
<M-]>   Siguiente sugerencia de Copilot (activa la primera)
<M-[>   Sugerencia anterior
<M-l>   Aceptar sugerencia completa
<M-j>   Aceptar línea
<M-k>   Aceptar palabra
<C-]>   Descartar sugerencia
```

---

### Edición de texto

#### Surround (mini.surround)

```
gsa   Add surround (ej: gsaiw" — rodear palabra con comillas)
gsd   Delete surround (ej: gsd" — eliminar comillas)
gsr   Replace surround (ej: gsr"' — cambiar " por ')
gsf   Find surround hacia adelante
gsh   Highlight surround
```

#### Text Objects (mini.ai)

Objetos de texto adicionales disponibles con `v`, `d`, `c`, `y`, etc.:

```
af/if   Function (around/inside)
ac/ic   Class
ao/io   Block (around/inside)
```

#### Yanky — historial de yank

```
<leader>py   Ver historial de yanks (snacks picker)
p / P        Pegar (con ciclo de historial disponible)
```

#### Otros atajos de edición

```
<C-s>        Guardar archivo
jk / jj      Escape desde insert mode
<M-j/k>      Mover línea hacia abajo/arriba
J/K          (visual) Mover selección hacia abajo/arriba
>/<          (visual) Indentar sin perder selección
<C-d/u>      Scroll + centrar cursor
n/N          Búsqueda + centrar cursor
<C-;>        Toggle `;` al final de la línea
<M-,>        Toggle `,` al final de la línea
```

---

### Debugger (DAP)

Requiere configurar adaptadores por lenguaje. Lee `.vscode/launch.json`
automáticamente si existe en el proyecto.

```
<leader>db   Toggle breakpoint
<leader>dB   Breakpoint condicional
<leader>dc   Continue / iniciar debug
<leader>dC   Ejecutar hasta el cursor
<leader>di   Step into
<leader>do   Step out
<leader>dO   Step over
<leader>dt   Terminar sesión
<leader>dr   Toggle REPL
<leader>dl   Ejecutar última configuración
<leader>du   Toggle DAP UI
<leader>dw   Hover de variables (DAP widgets)
<leader>ds   Ver sesión actual
```

El UI se abre y cierra automáticamente al iniciar/terminar una sesión.
Las variables de entorno de `.env` se cargan automáticamente para Go.

---

## Keymaps

> Presiona `<Space>` y espera — which-key mostrará todos los grupos
> disponibles con descripciones.

### Referencia rápida por grupo

| Prefijo     | Grupo                                                          |
| ----------- | -------------------------------------------------------------- |
| `<leader>a` | AI (Avante, Claude, Gemini, OpenCode)                          |
| `<leader>b` | Buffers                                                        |
| `<leader>c` | Code (format, actions, diagnostics, lint manual)               |
| `<leader>d` | Debug (DAP)                                                    |
| `<leader>e` | Explorer                                                       |
| `<leader>f` | File (new, path, chmod)                                        |
| `<leader>g` | Git                                                            |
| `<leader>h` | Harpoon                                                        |
| `<leader>l` | LSP (restart, hints, log, Mason)                               |
| `<leader>p` | Picker (archivos, grep, keymaps)                               |
| `<leader>q` | Sesiones / Quit                                                |
| `<leader>r` | Rename / Restart                                               |
| `<leader>s` | Search & Replace                                               |
| `<leader>u` | Toggle (format, diagnostics, hints, treesitter ctx, tema `uv`) |
| `<leader>v` | View / Help                                                    |
| `<leader>w` | Window (splits, hydra mode con `<C-w><Space>`)                 |
| `<leader>x` | Trouble / Diagnósticos                                         |
| `<leader>z` | Zen mode                                                       |
| `[` / `]`   | Navegación: `b`=buf `d`=diag `h`=hunk `q`=quickfix `t`=todo    |

### Buffers

```
<S-h> / <S-l>   Buffer anterior / siguiente (home row)
[b / ]b         Buffer anterior / siguiente (bracket style)
<leader>bd      Cerrar buffer
<leader>bD      Forzar cierre de buffer
<leader>bo      Cerrar todos los demás buffers
```

### Navegación de diagnósticos

```
]d / [d         Siguiente / anterior diagnóstico (abre float automáticamente)
<leader>cd      Abrir float del diagnóstico en línea actual
<leader>ud      Toggle mostrar/ocultar diagnósticos
```

### LSP global

```
<leader>lr      Reiniciar LSP del buffer actual
<leader>li      Toggle inlay hints (global)
<leader>ll      Ver log del LSP
<leader>lI      Ver info del LSP (:LspInfo)
<leader>lm      Abrir Mason
```

### Splits y ventanas

```
<leader>-       Split horizontal
<leader>|       Split vertical
<leader>we      Equalizar tamaño
<leader>wx      Cerrar split actual
<leader>wo      Cerrar otros splits
<C-w><Space>    Hydra mode — ver todos los comandos de ventana
<C-h/j/k/l>    Navegar entre splits
```

### Sesiones (Persistence)

```
<leader>qs   Guardar sesión actual
<leader>ql   Restaurar última sesión
<leader>qS   Seleccionar sesión guardada
<leader>qd   Eliminar sesión
```

---

## Personalización

### Agregar un plugin nuevo

Crea un archivo en `lua/Deadlock/plugins/mi-plugin.lua`:

```lua
return {
    "autor/mi-plugin",
    event = "VeryLazy",  -- o "BufReadPre", o usa 'keys'
    opts = {
        -- configuración del plugin
    },
    keys = {
        { "<leader>mp", "<cmd>MiPlugin<CR>", desc = "Mi Plugin" },
    },
}
```

lazy.nvim lo descubrirá automáticamente en el próximo inicio.

### Cambiar opciones de editor

Edita `lua/Deadlock/config/options.lua`. Las opciones siguen el esquema
`vim.opt.nombre = valor`.

### Agregar keymaps globales

Edita `lua/Deadlock/config/keymaps.lua`:

```lua
local key = vim.keymap.set

key("n", "<leader>mi", function()
    -- tu acción
end, { desc = "Mi keymap" })
```

### Agregar un LSP server nuevo

1. Agrega el nombre en `ensure_installed` en `lua/Deadlock/plugins/lsp/mason.lua`
2. Configúralo en `lua/Deadlock/plugins/lsp/lspconfig.lua`:

```lua
vim.lsp.config("mi_servidor", {
    -- configuración específica
})
vim.lsp.enable("mi_servidor")
```

### Agregar un formatter nuevo

En `lua/Deadlock/plugins/conform.lua`, agrega el filetype:

```lua
formatters_by_ft = {
    mi_lenguaje = { "mi_formatter" },
}
```

---

## Solución de problemas

### Ver qué está cargado y su tiempo de carga

```
:Lazy
:Lazy profile
```

### Ver estado de los LSP servers en el buffer actual

```
:LspInfo
:checkhealth lsp
```

### Ver estado de lazydev (tipos de Lua)

```
:checkhealth lazydev
```

### Verificar que blink.cmp está activo

```vim
:lua print(require("blink.cmp").get_lsp_capabilities ~= nil)
```

### Reiniciar el LSP del buffer actual

```
<leader>lr
```

### Ver notificaciones recientes

```
<leader>n
```

### El tema no carga / highlights incorrectos

```vim
" Recargar el tema manualmente:
:lua require("Deadlock.my-theme.init").colorscheme()

" Ver qué grupo aplica al texto bajo el cursor:
:Inspect
```

### Formateo no funciona

```vim
:ConformInfo     " Ver formatters disponibles para el buffer actual
:lua print(vim.b.disable_autoformat)  " Ver si está desactivado localmente
```

### Diagnósticos no aparecen

```vim
:lua vim.diagnostic.show()
" o toggle con:
<leader>ud
```

### Actualizar plugins

```
:Lazy update
```

### Actualizar LSP servers y tools

```
:MasonUpdate
```

### Herramientas AI no responden / error de API

```bash
# Verificar CLIs instalados
claude --version
gemini --version

# Reinstalar si es necesario
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
```

Para `avante.nvim` y `codecompanion`:

- Verifica que `ANTHROPIC_API_KEY` esté en tu entorno (`.bashrc`/`.zshrc`/`.env`)
- `:checkhealth avante` para diagnóstico completo

### Copilot no muestra sugerencias

Copilot está en **modo manual** — no auto-sugiere al escribir.
Actívalo con `<M-]>` en insert mode para ver la primera sugerencia.

Para volver a auto-trigger (acepta conflicto visual con blink.cmp):

```lua
-- en copilot.lua
auto_trigger = true,  -- y desactivar ghost_text en blink-cmp.lua
```

### Avante no renderiza Markdown en el panel

El panel de Avante usa `filetype=Avante`, que está incluido en render-markdown.
Si los headings no se renderizan:

```vim
:checkhealth render-markdown
```

---

_Para referencia técnica interna (arquitectura, decisiones de diseño, inventario
completo de plugins), ver la carpeta `CONTEXT/`._

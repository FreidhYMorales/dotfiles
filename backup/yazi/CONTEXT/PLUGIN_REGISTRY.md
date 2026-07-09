# PLUGIN_REGISTRY — Ficha técnica por plugin

Formato de cada entrada:

```
## [N] nombre-plugin
- Repo:        autor/repo
- setup():     SÍ / NO (ver I-03 en INVARIANTS.md)
- Tipo:        previewer | opener | plugin | flavor
- Dependencias: lista de paquetes del sistema
- Estado:      pendiente / instalado / configurado / ✅ ok / ⚠️ bug
- Keybind:     tecla(s) asignadas
- Bugs:        bugs conocidos o resueltos
- Notas:       detalles técnicos relevantes
```

---

## [01] bypass

- **Repo:** Rolv-Apneseth/bypass
- **setup():** NO — retorna tabla plana `{ entry = ... }`
- **Tipo:** plugin (intercepta acción `open`)
- **Dependencias:** ninguna
- **Estado:** ⬜ pendiente
- **Keybind:** automático (intercepta `l` / `Enter` / `→`)
- **Bugs:** —
- **Notas:** Abre directamente si hay un solo opener para el mime type. Si hay varios, deja pasar al picker. No interviene en directorios. Init: `require("bypass")` — sin `:setup()`.

---

## [03] relative-motions

- **Repo:** dedukun/relative-motions
- **setup():** SÍ
- **Tipo:** plugin (motions numéricos)
- **Dependencias:** ninguna
- **Estado:** ✅ instalado y funcionando
- **Keybind:** `1`–`9`
- **Bugs corregidos:**
  - Sintaxis de args era `--args=1` → correcto: `plugin relative-motions 1` (sin `--args=`)
  - Sección keymap era `[manager]` → correcto: `[mgr]` (Yazi 26.x)
- **Notas:** `setup({ show_numbers = "relative_absolute", show_motion = true })`. Keybind: `run = "plugin relative-motions N"`.

---

## [03] recycle-bin

- **Repo:** Rolv-Apneseth/recycle-bin
- **setup():** SÍ
- **Tipo:** plugin (trash seguro)
- **Dependencias:** `trash-cli` (pacman)
- **Estado:** ⬜ pendiente
- **Keybind:** `R,b` (borrar a papelera)
- **Bugs:** —
- **Notas:** Reemplaza el `d` (remove) de Yazi con papelera real. setup vacío `{}` es suficiente. Keybind: `run = "plugin recycle-bin"`.

---

## [02] clipboard

- **Repo:** XYenon/clipboard
- **Instalar:** `ya pkg add XYenon/clipboard`
- **setup():** NO — invocado on-demand por keybind, sin `require()` en init.lua
- **Tipo:** plugin (sincroniza yank de Yazi con clipboard del sistema)
- **Dependencias:** `wl-clipboard` — ya disponible en Hyprland/Wayland
- **Estado:** ✅ instalado y funcionando
- **Keybinds:** `y` (yank + copy) · `<C-p>` (paste)
- **Notas:** `y` ejecuta dos acciones: `yank` (Yazi interno) + `plugin clipboard -- --action=copy`. Así el yank nativo de Yazi sigue funcionando Y se sincroniza con wl-copy. Sin `require()` en init.lua — el plugin se carga cuando se invoca.

---

## [05] what-size

- **Repo:** pirafrank/what-size
- **setup():** SÍ — `what-size:setup({})` (setup vacío requerido)
- **Tipo:** plugin (calcular tamaño real de dir)
- **Dependencias:** ninguna
- **Estado:** ⬜ pendiente
- **Keybind:** `<C-s>`
- **Bugs:** —
- **Notas:** Sin `setup({})` no registra el widget de status. Keybind: `run = "plugin what-size"`.

---

## [06] fg

- **Repo:** Rolv-Apneseth/fg
- **setup():** SÍ
- **Tipo:** plugin (fuzzy find con ripgrep)
- **Dependencias:** `fd`, `fzf`, `ripgrep`
- **Estado:** ⬜ pendiente
- **Keybind:** `f,g`
- **Bugs:** —
- **Notas:** `default_action` DEBE ser `"jump"` (no `"nvim"` — ver I-04). Keybind: `run = "plugin fg"`.

---

## [07] lazygit

- **Repo:** Rolv-Apneseth/lazygit (plugin de Yazi)
- **setup():** NO — retorna tabla plana
- **Tipo:** plugin (abre lazygit en cwd)
- **Dependencias:** `lazygit` (pacman/aur)
- **Estado:** ⬜ pendiente
- **Keybind:** `g,i`
- **Bugs:** —
- **Notas:** Requiere `local_permits` en yazi.toml o usará shell externo. Scope cwd = directorio actual del panel. Init: `require("lazygit")`.

---

## [08] gvfs

- **Repo:** Rolv-Apneseth/gvfs
- **setup():** SÍ
- **Tipo:** plugin (montar unidades MTP/GVFS)
- **Dependencias:** `gvfs`, `gvfs-mtp`, `gvfs-gphoto2` (pacman)
- **Estado:** ⬜ pendiente
- **Keybind:** prefijo `M,*` (mount actions)
- **Bugs:** —
- **Notas:** Requiere `vfs.toml` para registrar los puntos de montaje. Keybinds múltiples para listar/montar/desmontar.

---

## [09] mount

- **Repo:** Rolv-Apneseth/mount
- **setup():** NO — retorna tabla plana
- **Tipo:** plugin (montar discos locales udisks2)
- **Dependencias:** `udisks2` (pacman)
- **Estado:** ⬜ pendiente
- **Keybind:** `M,M`
- **Bugs:** —
- **Notas:** Complementa a gvfs (gvfs = MTP/red, mount = discos/USB locales). Init: `require("mount")`.

---

## [10] ouch

- **Repo:** ndtoan96/ouch
- **setup():** NO — retorna tabla plana
- **Tipo:** previewer + opener (comprimir/descomprimir)
- **Dependencias:** `ouch` (aur: `ouch-bin`)
- **Estado:** ⬜ pendiente
- **Keybind:** `C` (comprimir seleccionados)
- **Bugs:** —
- **Notas:** También actúa como previewer de archivos comprimidos. Init: `require("ouch")`. Registrar en `[plugin] previewers` de yazi.toml.

---

## [11] piper

- **Repo:** Rolv-Apneseth/piper
- **setup():** NO — retorna tabla plana
- **Tipo:** plugin (pipe output de comandos al panel)
- **Dependencias:** ninguna
- **Estado:** ⬜ pendiente
- **Keybind:** ninguno asignado (uso programático)
- **Bugs:** —
- **Notas:** Uso avanzado — pipe stdout de shell commands a Yazi. Sin keybind activo hasta definir casos de uso.

---

## [12] rich-preview

- **Repo:** Rolv-Apneseth/rich-preview
- **setup():** NO — retorna tabla plana
- **Tipo:** previewer (código con syntax highlight rico)
- **Dependencias:** `rich-cli` (pip) o `python-rich`
- **Estado:** ⬜ pendiente
- **Keybind:** automático (previewer para código)
- **Bugs:** —
- **Notas:** Registrar en `[plugin] previewers` antes de la regla `text/*` de fallback. Init: `require("rich-preview")`.

---

## [13] glow

- **Repo:** Rolv-Apneseth/glow
- **setup():** NO — retorna tabla plana
- **Tipo:** previewer (Markdown renderizado)
- **Dependencias:** `glow` (pacman)
- **Estado:** ⬜ pendiente
- **Keybind:** automático (`*.md` files)
- **Bugs:** —
- **Notas:** Registrar en previewers para `mime = "text/markdown"`. El ancho del preview se pasa como arg. Init: `require("glow")`.

---

## [14] hexyl

- **Repo:** Rolv-Apneseth/hexyl
- **setup():** NO — retorna tabla plana
- **Tipo:** previewer (hex dump)
- **Dependencias:** `hexyl` (pacman)
- **Estado:** ⬜ pendiente
- **Keybind:** automático (`application/octet-stream`)
- **Bugs:** —
- **Notas:** Registrar en previewers para binarios. Lógica de fallback: si hexyl falla, Yazi usa su previewer built-in. Init: `require("hexyl")`.

---

## [15] mediainfo

- **Repo:** Rolv-Apneseth/mediainfo
- **setup():** NO — retorna tabla plana
- **Tipo:** previewer (metadata de audio/video/imagen)
- **Dependencias:** `mediainfo` (pacman)
- **Estado:** ⬜ pendiente
- **Keybind:** `I` (manual) + automático para media
- **Bugs:** —
- **Notas:** Registrar en previewers para `video/*` y `audio/*`. Init: `require("mediainfo")`.

---

## [01] yatline

- **Repo:** imsi32/yatline
- **Instalar:** `ya pkg add imsi32/yatline`
- **setup():** SÍ
- **Tipo:** UI (header line + status line)
- **Dependencias:** Nerd Font activa en Kitty
- **Estado:** ✅ instalado y funcionando
- **Keybind:** automático (UI permanente)
- **Bugs corregidos:**
  - Repo era `Rolv-Apneseth/yatline` → correcto es `imsi32/yatline`
  - Nombres de componentes tenían prefijo `get_` incorrecto → eliminado
  - `style_a` usaba `bg` plano → corregido a `bg_mode { normal, select, un_set }`
  - `arg =` en date → corregido a `params = { }`
  - `get_cwd` no existe → reemplazado por `{ type="line", name="tabs" }`
  - Colores en Lua usaban "bright-black" → correcto es "brightblack" (sin guión)
  - Faltaban: `padding`, `tab_width`, `show_background`, iconos de count/tasks
- **Notas:** `show_background = false` → bars transparentes (terminal-native). Header: tabs izq + hora der. Status: modo/tamaño/nombre izq · posición/porcentaje/extensión+permisos der.

---

## [17] starship

- **Repo:** Rolv-Apneseth/starship (plugin de Yazi)
- **setup():** SÍ
- **Tipo:** UI (header con prompt de starship)
- **Dependencias:** `starship` (pacman/cargo)
- **Estado:** ⬜ pendiente
- **Keybind:** automático (UI permanente)
- **Bugs:** —
- **Notas:** INVARIANTE: cargar DESPUÉS de yatline. Usa `Header:children_remove` + `Header:children_add` para tomar el header. Requiere starship instalado y configurado en el sistema.

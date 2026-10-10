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
- **Notas:** En archivos emite `open --hovered` (no interactivo): ejecuta siempre el PRIMER opener de la regla que coincide; el menú con todos los openers es `O`. No interviene en directorios. Init: `require("bypass")` — sin `:setup()`.

---

## [03] relative-motions

- **Repo:** boydaihungst/relative-motions (fork)
- **Instalar:** `ya pkg add boydaihungst/relative-motions`
- **setup():** SÍ
- **Tipo:** plugin (motions numéricos)
- **Dependencias:** ninguna
- **Estado:** ✅ instalado y funcionando (verificado en Yazi 26.9.1)
- **Keybind:** `1`–`9`
- **Bugs corregidos:**
  - Repo original `dedukun/relative-motions` (sin mantenimiento desde 2025-07) llamaba a `ya.mgr_emit`, removido en Yazi 26 → `3j`/`5k` saltaban a posiciones incorrectas. Reemplazado por el fork, que usa `ya.emit`/`ui.render` (ver I-10). El fork también está marcado como sin mantenimiento por su autor.
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

## [02] sys-clipboard

- **Repo:** local — `plugins/sys-clipboard.yazi/`, copia de XYenon/clipboard @ a2655fd (AGPL-3.0, LICENSE incluida)
- **Instalar:** versionado en el repo (excepción en `.gitignore`); no viene de `ya pkg`. Para actualizar: bajar `main.lua` del upstream y conservar el encabezado
- **setup():** NO — invocado on-demand por keybind, sin `require()` en init.lua
- **Tipo:** plugin (sincroniza yank de Yazi con clipboard del sistema)
- **Dependencias:** `wl-clipboard` — ya disponible en Hyprland/Wayland
- **Estado:** ✅ instalado y funcionando
- **Keybinds:** `y` (yank + copy) · `<C-p>` (paste)
- **Notas:** `y` ejecuta dos acciones: `yank` (Yazi interno) + `plugin sys-clipboard -- --action=copy`. Así el yank nativo de Yazi sigue funcionando Y se sincroniza con wl-copy. Sin `require()` en init.lua — el plugin se carga cuando se invoca. Renombrado de `clipboard` porque Yazi 26.x trae un built-in con ese nombre (avisa "deprecated as a custom plugin name").

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

## [06] fr

- **Repo:** lpnh/fr
- **Instalar:** `ya pkg add lpnh/fr` (fijado en `package.toml`, sin clone manual)
- **setup():** opcional — esta config no lo invoca (sin `require("fr"):setup()`)
- **Tipo:** plugin (búsqueda de contenido con rg/rga + fzf + preview con bat)
- **Dependencias:** `fzf`, `ripgrep`, `bat`; `ripgrep-all` (rga) para `g,R`
- **Estado:** ✅ instalado y funcionando
- **Keybind:** `g,r` (`plugin fr rg`) · `g,R` (`plugin fr rga`, incluye PDFs/documentos)
- **Bugs corregidos:**
  - Reemplaza a `DreamMaoMao/fg.yazi` (clone manual, archivado 2026-09, usaba `ya.mgr_emit` — ver I-10)
- **Notas:** Hace `reveal` del resultado en Yazi — navega, nunca abre el editor (I-04). Dentro de fzf: `<C-s>` alterna match rg/fzf, `<C-r>` recarga, `<C-\>` cambia la posición del preview, `<C-]>` cambia el tamaño del preview. La búsqueda por nombre (`z`) usa el plugin `fzf` built-in de Yazi, no `fr`.

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

---

## [16] git

- **Repo:** yazi-rs/plugins:git (oficial)
- **setup():** SÍ — `require("git"):setup({ order = 1500 })`
- **Tipo:** fetcher + linemode (estado git por archivo/carpeta)
- **Dependencias:** `git`
- **Estado:** ✅ instalado y verificado en vivo (Yazi 26.9.1)
- **Keybind:** automático (signo en el linemode de la derecha)
- **Bugs:** —
- **Notas:** Requiere registrar los fetchers en `yazi.toml` `[plugin] prepend_fetchers` (`url = "*"` y `url = "*/"`, `run = "git"`, `group = "git"`). Sin los fetchers, el setup no muestra nada.

---

## [17] toggle-pane

- **Repo:** yazi-rs/plugins:toggle-pane (oficial)
- **setup():** NO
- **Tipo:** plugin on-demand
- **Dependencias:** —
- **Estado:** ✅ instalado y verificado en vivo (Yazi 26.9.1)
- **Keybind:** `<A-p>` max-preview · `<A-P>` min-preview (`T` del README choca con tab_create)
- **Bugs:** —
- **Notas:** Maximizar/ocultar el panel de preview (`max-preview` / `min-preview`).

---

## [18] chmod

- **Repo:** yazi-rs/plugins:chmod (oficial)
- **setup():** NO
- **Tipo:** plugin on-demand
- **Dependencias:** —
- **Estado:** ✅ instalado y verificado en vivo (Yazi 26.9.1)
- **Keybind:** `c,m`
- **Bugs:** —
- **Notas:** Pide el modo en un input y aplica `chmod` a la selección.

---

## [19] ouch-extract (local)

- **Repo:** local — `plugins/ouch-extract.yazi/` (versionado en el repo, excepción en `.gitignore`; no lo gestiona `ya pkg`)
- **setup():** NO
- **Tipo:** plugin on-demand, invocado por el opener `extract` de `yazi.toml` (`ya emit plugin ouch-extract`)
- **Dependencias:** `ouch` ≥ 0.8 (lee la contraseña de `OUCH_PASSWORD`)
- **Estado:** ✅ verificado en vivo (zip/7z cifrados, contraseña incorrecta, cancelar, sin contraseña, colisión de nombre)
- **Keybind:** `Enter`/`l` sobre un archivo comprimido (regla `[open]` de archives)
- **Bugs:** —
- **Notas:** Extrae a una carpeta temporal oculta junto al archivo y solo mueve el resultado si ouch terminó bien — ouch deja carpetas a medio escribir (y en 7z hasta archivos basura) cuando falta o es incorrecta la contraseña. Si detecta "password" en el error, abre un input con `obscure = true` (texto oculto) y reintenta; `Esc` cancela. La contraseña viaja por variable de entorno, nunca por argv (no aparece en `ps`). Si el destino ya existe, usa un nombre libre (`plain_1`). Reemplaza al viejo `scripts/ouch-extract.sh`, que no estaba conectado y tenía la contraseña en argv.


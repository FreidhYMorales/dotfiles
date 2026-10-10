# Módulo 5 — Troubleshooting & Debug

---

## 5.1 Activar Logs

```toml
# yazi.toml — activar temporalmente para debug
[log]
enabled = true
```

```bash
# Ubicación del log
tail -f ~/.local/share/yazi/yazi.log

# O lanzar Yazi y capturar stderr directamente
YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi 2>/tmp/yazi-debug.log
tail -f /tmp/yazi-debug.log
```

**Desactivar tras el debug** — el log en modo activo puede crecer rápido.

---

## 5.2 Diagnóstico Rápido

```bash
# 1. Verificar que Yazi carga la config correcta
YAZI_CONFIG_HOME=/home/deadlock/Files/Configuraciones/yazi yazi --debug 2>&1 | head -20

# 2. Verificar symlink de plugins
ls -la /home/deadlock/Files/Configuraciones/yazi/plugins
# Esperado: plugins -> /home/deadlock/.config/yazi/plugins  (o ~/.config/yazi/plugins)

# 3. Verificar herramientas en PATH
which fzf rg bat glow hexyl mediainfo ouch lazygit trash-put wl-copy rich

# 4. Verificar plugins instalados
ls ~/.config/yazi/plugins/
```

---

## 5.3 Tabla de Errores Comunes

### Keybinds no responden

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| Ningún keybind custom funciona | `[manager]` en lugar de `[mgr]` | Cambiar a `[mgr]` en keymap.toml |
| Plugin keybind no hace nada | Symlink `plugins/` roto o ausente | `ln -s ~/.config/yazi/plugins $YAZI_CONFIG_HOME/plugins` |
| Plugin no recibe argumentos | Sintaxis `--args=val` | Cambiar a `plugin name val` (espacio directo) |
| Chord `["s","n"]` no funciona | Otro bind consume `s` antes | Verificar que `prepend_keymap` esté activo |
| Binds del picker no responden | Sección `[select]` (no existe esa capa en 26.x) | Usar `[pick]`; capas válidas: `mgr`, `tasks`, `spot`, `pick`, `input`, `confirm`, `help`, `cmp` |
| Bind de input no hace nada | Comando inválido (`kill-line-to-start`, `kill-line`) | Usar `kill bol` / `kill eol`, o no declararlo (son defaults) |
| `X` cierra otra pestaña | `tab_close 0` usa índice absoluto (cierra la primera) | Usar `close` (pestaña actual; sale si es la última) |
| `!` no ejecuta nada | `shell --block --confirm` (`--confirm` ya no existe) | `shell --block --interactive` |
| `,m` (antes `s,m`) no ordena | `sort modified` — `modified` no es `SortBy` válido | `sort mtime`; válidos: `none`, `mtime`, `btime`, `extension`, `alphabetical`, `natural`, `size`, `random` |

### Preview no funciona

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `.md` muestra texto plano | glow no emite ANSI sin TTY | Añadir `CLICOLOR_FORCE=1` antes de glow |
| Video no muestra thumbnail | mediainfo en `prepend_previewers` sobreescribe built-in | Mover video/* a `append_previewers` o eliminarlo |
| Archivo comprimido no muestra contenido | ouch no instalado | `sudo pacman -S ouch` |
| Binarios sin preview | hexyl no instalado | `sudo pacman -S hexyl` |
| `rich` falla en preview | rich-cli no en PATH | `pipx install rich-cli` o `yay -S rich-cli` |

### Colores del theme no se aplican (sin ningún error)

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| Cursor sigue en reverse por defecto, dirs sin negrita, tabs/modo sin color | Secciones/claves pre-26.x (`[manager]`, `hovered`, `tab_active`, `mode_normal`, `separator_open`, `permissions_*`, `[completion]`…) — Yazi las ignora en silencio | Migrar al esquema 26.x (tabla en I-11); comparar el flavor contra el preset upstream `theme-dark.toml` |
| Reglas de `[filetype]` sin efecto | Estilo anidado `style = { fg = ... }` — ignorado en silencio | Claves planas sobre la regla: `{ url = "*/", fg = "blue", bold = true }` (I-05) |
| Ocultos sin color propio | `url = ".*"` — los patrones comparan la ruta completa, nunca matchea | `{ url = "*", is = "hidden", ... }` |

### Openers no reciben el archivo

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `xdg-open` imprime su propio `--help`/usage y sale con status 1 | `run = 'cmd "$@"'` o `'cmd "$1"'` en `[opener]` — sintaxis de shell real, que Yazi 26.x no sustituye y deja como texto muerto | Usar los placeholders propios de Yazi: `%s` (todos los archivos seleccionados), `%s1` (solo el primero), `%d1` (dirname del primero) — ver [docs oficiales](https://yazi-rs.github.io/docs/configuration/yazi/#opener) |
| nvim (u otro opener sin validación de argv) abre pero con buffer/ventana vacía, sin abrir el archivo esperado | Mismo problema — a diferencia de xdg-open, estos programas no fallan visiblemente con 0 argumentos, así que pasa desapercibido | Igual que arriba — revisar TODOS los openers de `[opener]`, no solo el que falló visible |

### Yazi no arranca

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `missing comma between array elements` en preloaders/previewers | Campo `name =` (renombrado a `url =` en 26.x) | Cambiar `name =` por `url =` en `[plugin]` de yazi.toml |
| `at least one of url or mime must be specified` en filetype rules | `is = "..."` sin `url` o `mime` acompañante | Añadir `url = "*"` (archivos) o `url = "*/"` (directorios) junto al `is =`, o eliminar la entrada |
| `at least one of url or mime must be specified` con `is = "dir"` | `is = "dir"` — valor inválido en Yazi 26.x | Cambiar a `url = "*/"` (barra final = solo directorios; `mime = "inode/directory"` no matchea en 26.x, los dirs son `folder/*`) |
| `data did not match any variant of untagged enum CustomField` | `tab_width = 1` en `[mgr]` (antes `[manager]`) del flavor | Eliminar la línea; `tab_width` ya no es campo válido de flavor |
| Runtime crash en init.lua | `:setup()` en plugin sin setup() | Verificar `tail -1 main.lua` del plugin |
| `Error: unknown field` | Campo TOML incorrecto | Revisar INVARIANTS.md |

### Plugins con comportamiento incorrecto

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `sys-clipboard` no copia | wl-clipboard no instalado | `sudo pacman -S wl-clipboard` |
| `sys-clipboard` parece no funcionar | MIME type equivocado al verificar | Usar `wl-paste -t text/uri-list` |
| Aviso "`clipboard` is deprecated as a custom plugin name" | Existe `plugins/clipboard.yazi` (choca con el built-in de Yazi 26.x) | Renombrar el plugin y actualizar `keymap.toml` — acá vive como `sys-clipboard` |
| `relative-motions` salta mal (`3j`/`5k` erráticos) o la búsqueda de contenido (antiguo `fg.yazi`) falla; error `attempt to call a nil value (field 'mgr_emit')` | El plugin usa `ya.mgr_emit`, removido en Yazi 26 (I-10) | Usar el fork `boydaihungst/relative-motions` y `lpnh/fr` (reemplazo de `fg.yazi`); en plugins locales, cambiar `ya.mgr_emit` por `ya.emit`. Detectar: `rg -n mgr_emit plugins/` |
| `g,R` no encuentra nada en PDFs/documentos | `ripgrep-all` (rga) no instalado | `sudo pacman -S ripgrep-all` |
| `gvfs` no muestra dispositivos MTP | gvfs-mtp no instalado | `sudo pacman -S gvfs-mtp` |
| `recycle-bin` falla al restaurar | trash-cli no instalado | `sudo pacman -S trash-cli` |

---

## 5.4 Procedimientos de Inspección

### Inspeccionar un plugin antes de instalarlo

```bash
# Ver el return del main.lua para saber si necesita setup()
curl -s https://raw.githubusercontent.com/<repo>/main/main.lua | tail -5

# O si ya está instalado:
tail -5 ~/.config/yazi/plugins/<plugin>.yazi/main.lua
```

### Verificar que un previewer se activa

```bash
# Activar log, navegar al archivo, revisar el log
YAZI_CONFIG_HOME=... yazi 2>/tmp/yazi.log &
# Navegar al archivo problemático
grep -i "preview\|error\|plugin" /tmp/yazi.log
```

### Verificar MIME type de un archivo

```bash
# Lo que Yazi ve
file --mime-type archivo.xyz

# Ejemplos relevantes
file --mime-type video.mp4     # → video/mp4
file --mime-type audio.flac    # → audio/x-flac
file --mime-type archivo.zip   # → application/zip
file --mime-type archivo.tar.gz # → application/gzip
```

Comparar el MIME type real con los patrones en `prepend_previewers`. Si no coincide, el previewer no se activa.

### Debug de keybind específico

```bash
# En Yazi, pulsar ~ para abrir el panel de ayuda
# Buscar el keybind — si no aparece, no está cargado
```

---

## 5.5 Anti-Patrones — Referencia Rápida

> Lista completa en `CONTEXT/INVARIANTS.md`

| Anti-patrón | Consecuencia |
|-------------|-------------|
| `[manager]` en keymap.toml | Todos los custom keybinds ignorados |
| `plugin name --args=val` | Plugin no recibe argumentos |
| `name =` en previewers/preloaders de yazi.toml | Yazi no arranca (renombrado a `url =` en 26.x) |
| `is = "..."` solo en filetype rules (sin url/mime) | Yazi no arranca |
| `is = "dir"` en filetype rules | Yazi no arranca ("dir" no válido; usar `url = "*/"`) |
| `style = { ... }` anidado en filetype rules | Ignorado en silencio (usar claves planas) |
| `[select]` en keymap.toml | Sección ignorada (la capa es `[pick]`) |
| `ya.mgr_emit` en un plugin | Removido en Yazi 26 — usar `ya.emit` |
| `tab_width = 1` en `[mgr]` del flavor | Yazi no arranca (campo eliminado en 26.x) |
| `require("bypass"):setup()` | Runtime crash |
| `require("mount"):setup()` | Runtime crash |
| Hex colors en theme.toml | Rompe herencia de colorscheme de Kitty |
| `plugin <name>` sin symlink `plugins/` | Falla silenciosamente sin notificación |
| `"bright-black"` en init.lua | Color no aplica (sin error) |
| `"brightblack"` en theme.toml | Color no aplica (sin error) |
| Plugin de búsqueda que abre nvim en vez de navegar | Viola separación CLI/editor (I-04) |
| `"$@"`/`"$1"` (sintaxis shell) en `run =` de `[opener]` | Yazi 26.x no lo sustituye — el opener corre sin archivo. Usar `%s`/`%s1`/`%d1` |

---

## 5.6 Reset de Emergencia

Si Yazi no arranca y no está claro el error:

```bash
# 1. Probar con config mínima (sin plugins, sin custom config)
yazi

# 2. Si funciona, activar archivos uno a uno
YAZI_CONFIG_HOME=... yazi  # con config completa

# 3. Aislar el archivo problemático comentando secciones en init.lua
# Comentar desde el final hacia arriba hasta que Yazi arranque

# 4. Una vez identificado el plugin, verificar:
tail -1 ~/.config/yazi/plugins/<plugin>.yazi/main.lua
# y comparar con lo que está en init.lua

# 5. Verificar el log
YAZI_CONFIG_HOME=... yazi 2>&1 | head -50
```

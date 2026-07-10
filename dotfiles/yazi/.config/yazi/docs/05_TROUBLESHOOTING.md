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

### Preview no funciona

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `.md` muestra texto plano | glow no emite ANSI sin TTY | Añadir `CLICOLOR_FORCE=1` antes de glow |
| Video no muestra thumbnail | mediainfo en `prepend_previewers` sobreescribe built-in | Mover video/* a `append_previewers` o eliminarlo |
| Archivo comprimido no muestra contenido | ouch no instalado | `sudo pacman -S ouch` |
| Binarios sin preview | hexyl no instalado | `sudo pacman -S hexyl` |
| `rich` falla en preview | rich-cli no en PATH | `pipx install rich-cli` o `yay -S rich-cli` |

### Yazi no arranca

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `missing comma between array elements` en preloaders/previewers | Campo `name =` (renombrado a `url =` en 26.x) | Cambiar `name =` por `url =` en `[plugin]` de yazi.toml |
| `at least one of url or mime must be specified` en filetype rules | `is = "..."` sin `url` o `mime` acompañante | Añadir `url = "**/*"` junto al `is =`, o eliminar la entrada |
| `at least one of url or mime must be specified` con `is = "dir"` | `is = "dir"` — valor inválido en Yazi 26.x | Cambiar a `mime = "inode/directory"` |
| `data did not match any variant of untagged enum CustomField` | `tab_width = 1` en `[manager]` del flavor | Eliminar la línea; `tab_width` ya no es campo válido de flavor |
| Runtime crash en init.lua | `:setup()` en plugin sin setup() | Verificar `tail -1 main.lua` del plugin |
| `Error: unknown field` | Campo TOML incorrecto | Revisar INVARIANTS.md |

### Plugins con comportamiento incorrecto

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `clipboard` no copia | wl-clipboard no instalado | `sudo pacman -S wl-clipboard` |
| `clipboard` parece no funcionar | MIME type equivocado al verificar | Usar `wl-paste -t text/uri-list` |
| `fg` abre editor en lugar de navegar | `default_action = "nvim"` | Cambiar a `default_action = "jump"` |
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
| `is = "dir"` en filetype rules | Yazi no arranca ("dir" no válido; usar `mime = "inode/directory"`) |
| `tab_width = 1` en `[manager]` del flavor | Yazi no arranca (campo eliminado en 26.x) |
| `require("bypass"):setup()` | Runtime crash |
| `require("mount"):setup()` | Runtime crash |
| Hex colors en theme.toml | Rompe herencia de colorscheme de Kitty |
| `plugin <name>` sin symlink `plugins/` | Falla silenciosamente sin notificación |
| `"bright-black"` en init.lua | Color no aplica (sin error) |
| `"brightblack"` en theme.toml | Color no aplica (sin error) |
| `default_action = "nvim"` en fg | Viola separación CLI/editor |

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

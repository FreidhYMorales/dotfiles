-- ============================================================
--  init.lua — Plugin setup & UI customization
--  Load order matters. See CONTEXT/INVARIANTS.md I-02, I-03.
-- ============================================================

-- ============================================================
--  SECTION 1 — Built-in UI tweaks (no plugins required)
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  [00] full-border — Borde completo alrededor del manager
--  Repo:    yazi-rs/plugins:full-border  (ya pkg add yazi-rs/plugins:full-border)
--  setup(): YES — cargado en Section 1, antes que cualquier plugin de UI
--  Tipo:    ui.Border.PLAIN (esquinas rectas, estilo terminal-alike)
-- ─────────────────────────────────────────────────────────────
require("full-border"):setup({
	type = ui.Border.PLAIN,
})

-- ============================================================
--  SECTION 2 — Plugins (installation order = load order)
--
--  INVARIANT I-03: check return type before calling :setup()
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  [01] yatline — Header + Status line UI
--  Repo:    imsi32/yatline  (ya pkg add imsi32/yatline)
--  setup(): YES
--  API ref: https://github.com/imsi32/yatline.yazi/wiki
--
--  NOTA: en Lua, los nombres de color NO llevan guion:
--    "brightblack" no "bright-black"  (diferente de theme.toml)
-- ─────────────────────────────────────────────────────────────
require("yatline"):setup({
	-- Separadores powerline (requiere Nerd Font en Kitty)
	section_separator = { open = "", close = "" },
	part_separator = { open = "", close = "" },
	inverse_separator = { open = "", close = "" },

	-- Padding alrededor de componentes (nº de espacios)
	padding = { inner = 1, outer = 1 },

	-- style_a: sección activa — cambia color según modo del tab
	-- style_b: sección secundaria
	-- style_c: sección de texto / fondo del bar completo si show_background=true
	-- ANSI en Lua: sin guion ("brightblack", no "bright-black")
	style_a = {
		fg = "black",
		bg_mode = {
			normal = "blue",
			select = "green",
			un_set = "red",
		},
	},
	style_b = { bg = "brightblack", fg = "white" },
	style_c = { bg = "black", fg = "brightwhite" },

	-- Colores de permisos (componente `permissions`)
	permissions_t_fg = "green",
	permissions_r_fg = "yellow",
	permissions_w_fg = "red",
	permissions_x_fg = "cyan",
	permissions_s_fg = "white",

	-- Ancho de cada tab en el header (0 = sin texto, solo icono)
	tab_width = 20,

	-- Iconos y colores del componente `count`
	selected = { icon = "󰻭", fg = "yellow" },
	copied = { icon = "", fg = "green" },
	cut = { icon = "", fg = "red" },
	files = { icon = "", fg = "blue" },
	filtereds = { icon = "", fg = "magenta" },

	-- Iconos y colores del componente `task_states`
	total = { icon = "󰮍", fg = "yellow" },
	success = { icon = "", fg = "green" },
	failed = { icon = "", fg = "red" },

	-- false → el fondo del bar completo es transparente (terminal-native)
	show_background = false,

	display_header_line = true,
	display_status_line = true,

	-- Orden vertical: header arriba, tab en medio, status abajo (default)
	component_positions = { "header", "tab", "status" },

	-- ── Header line ─────────────────────────────────────────────
	-- Izquierda: tabs (component tipo "line" — muestra pestañas abiertas)
	-- Derecha:   hora
	header_line = {
		left = {
			section_a = {
				{ type = "line", custom = false, name = "tabs", params = { "left" } },
			},
			section_b = {},
			section_c = {},
		},
		right = {
			section_a = {
				{ type = "string", custom = false, name = "date", params = { "%H:%M" } },
			},
			section_b = {},
			section_c = {},
		},
	},

	-- ── Status line ─────────────────────────────────────────────
	-- Izquierda: modo | tamaño | nombre del archivo + count
	-- Derecha:   posición | porcentaje | extensión + permisos
	status_line = {
		left = {
			section_a = {
				{ type = "string", custom = false, name = "tab_mode" },
			},
			section_b = {
				{ type = "string", custom = false, name = "hovered_size" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_name" },
				{ type = "coloreds", custom = false, name = "count" },
			},
		},
		right = {
			section_a = {
				{ type = "string", custom = false, name = "cursor_position" },
			},
			section_b = {
				{ type = "string", custom = false, name = "cursor_percentage" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_file_extension", params = { true } },
				{ type = "coloreds", custom = false, name = "permissions" },
			},
		},
	},
})

-- Override: upstream yatline (c5d4b48) still calls the deprecated
-- `File:icon()`, which Yazi 26.x flags with a "Deprecated API" popup.
-- Plugins are gitignored and reinstalled by `ya pkg`, so the fix lives here.
function Yatline.string.get:hovered_file_extension(show_icon)
	local hovered = cx.active.current.hovered
	if not hovered then
		return ""
	end

	local name = hovered.cha.is_dir and "dir" or (hovered.url.name:match("^.+%.(.+)$") or "null")
	if not show_icon then
		return name
	end

	local icon = th.icon:match(hovered)
	return icon and (icon.text .. " " .. name) or name
end

-- ─────────────────────────────────────────────────────────────
--  [02] clipboard — Sincroniza yank de Yazi con el clipboard del sistema
--  Repo:    XYenon/clipboard  (ya pkg add XYenon/clipboard)
--  Dep:     wl-clipboard (wl-copy) — ya disponible en Hyprland
--  setup(): NO — se invoca on-demand via keybind, no requiere require()
-- ─────────────────────────────────────────────────────────────
-- (sin require — el plugin se carga automáticamente al invocarse por keybind)

-- ─────────────────────────────────────────────────────────────
--  [03] relative-motions — Movimientos numéricos tipo Vim (5j, 3k)
--  Repo:    boydaihungst/relative-motions  (ya pkg add boydaihungst/relative-motions)
--  Nota:    fork — dedukun/relative-motions (abandonado 2025-07) usa ya.mgr_emit,
--           que ya no existe en Yazi 26 (los motions saltaban mal). El fork
--           migró a ya.emit/ui.render. También está marcado sin mantenimiento:
--           revisar alternativas si una futura versión de Yazi lo rompe.
--  setup(): YES
-- ─────────────────────────────────────────────────────────────
require("relative-motions"):setup({
	-- "relative_absolute": números relativos + absoluto en la línea del cursor
	-- "relative":          solo números relativos
	-- "absolute":          solo número absoluto (comportamiento estándar)
	show_numbers = "relative_absolute",
	show_motion = true, -- muestra el motion activo (ej: "3j") en el status
})

-- ─────────────────────────────────────────────────────────────
--  [04] bypass — Smart enter: atraviesa dirs de hijo único
--  Repo:    Rolv-Apneseth/bypass  (ya pkg add Rolv-Apneseth/bypass)
--  setup(): NO — tabla plana, invocado via keybind
--  Keybind: l → plugin bypass smart-enter
-- ─────────────────────────────────────────────────────────────
-- (sin require — el plugin se carga al invocarse por keybind)

-- ─────────────────────────────────────────────────────────────
--  [05] fr — Búsqueda de contenido con rg/rga + fzf + preview bat
--  Repo:    lpnh/fr  (ya pkg add lpnh/fr)
--  Deps:    fzf, ripgrep, bat, ripgrep-all (rga, opcional — solo `f,G`)
--  setup(): NO — opcional, solo para pasar flags extra a fzf/rg/bat/rga
--  Keybind: f,g → rg | f,G → rga | f,f → plugin fzf built-in (por nombre)
--  Reemplaza a DreamMaoMao/fg.yazi (archivado 2026-09, usaba ya.mgr_emit).
--  INVARIANT I-04 se mantiene: fr hace `reveal` del resultado (salta al
--  archivo dentro de Yazi), nunca abre un editor.
-- ─────────────────────────────────────────────────────────────
-- (sin require — invocado on-demand via keybind)

-- ─────────────────────────────────────────────────────────────
--  [06] gvfs — Montar/desmontar dispositivos MTP/SFTP/SMB via GVFS
--  Repo:    boydaihungst/gvfs  (ya pkg add boydaihungst/gvfs)
--  Deps:    gvfs, gvfs-mtp, gvfs-backends
--  setup(): YES
-- ─────────────────────────────────────────────────────────────
if ya.uid then
	require("gvfs"):setup({
		-- Teclas para seleccionar dispositivos en el picker
		which_keys = "1234567890qwertyuiopasdfghjklzxcvbnm",
		-- Ocultar el filesystem local del picker (scheme "file")
		blacklist_devices = { { scheme = "file" } },
		-- Rutas de guardado de configuración persistente
		save_path = os.getenv("HOME") .. "/.config/yazi/gvfs.private",
		save_path_automounts = os.getenv("HOME") .. "/.config/yazi/gvfs_automounts.private",
		input_position = { "center", y = 0, w = 60 },
	})
end

-- ─────────────────────────────────────────────────────────────
--  [07] mount — Gestor de discos locales (udisks2)
--  Repo:    yazi-rs/plugins:mount  (ya pkg add yazi-rs/plugins:mount)
--  Deps:    udisks2, lsblk, eject (util-linux)
--  setup(): NO — invocado on-demand via keybind
--  Keybind: M,M (no conflicta con gvfs que usa M,m/u/U/a/e/r)
-- ─────────────────────────────────────────────────────────────
-- (sin require — carga on-demand al invocarse)

-- ─────────────────────────────────────────────────────────────
--  [08] rich-preview — Preview enriquecido via Python rich-cli
--  Repo:    AnirudhG07/rich-preview  (ya pkg add AnirudhG07/rich-preview)
--  Dep:     rich-cli (yay -S rich-cli  o  pipx install rich-cli)
--  setup(): NO — configurado solo via prepend_previewers en yazi.toml
--  Tipos:   *.csv, *.rst, *.ipynb  (*.json → built-in bat; *.md → glow)
-- ─────────────────────────────────────────────────────────────
-- (sin require — el plugin es un previewer puro, no se invoca vía keybind)

-- ─────────────────────────────────────────────────────────────
--  [piper] — Wrapper de comandos shell como previewers
--  Repo:    yazi-rs/plugins:piper  (ya pkg add yazi-rs/plugins:piper)
--  setup(): NO — configurado solo via prepend/append_previewers en yazi.toml
--  Usado por: glow (*.md), hexyl (fallback *), mediainfo (video/audio)
-- ─────────────────────────────────────────────────────────────
-- (sin require — previewer puro)

-- ─────────────────────────────────────────────────────────────
--  [09] glow — via piper (no plugin .yazi separado)
--  Herramienta: glow (sudo pacman -S glow)
--  Configured: prepend_previewers *.md en yazi.toml
-- ─────────────────────────────────────────────────────────────
-- (sin require — previewer puro vía piper)

-- ─────────────────────────────────────────────────────────────
--  [10] hexyl — via piper (no plugin .yazi separado)
--  Herramienta: hexyl (sudo pacman -S hexyl)
--  Configured: append_previewers * (fallback) en yazi.toml
-- ─────────────────────────────────────────────────────────────
-- (sin require — previewer puro vía piper)

-- ─────────────────────────────────────────────────────────────
--  [11] mediainfo — Plugin dedicado con toggle thumbnail/metadata
--  Repo:    boydaihungst/mediainfo  (ya pkg add boydaihungst/mediainfo)
--  Deps:    mediainfo, imagemagick, ffmpeg (opcional)
--  setup(): NO — configurado via prepend_preloaders/previewers en yazi.toml
--  Keybind: I → toggle-metadata (thumbnail ↔ info texto)
--  Tipos:   audio/*, video/*, image/*
-- ─────────────────────────────────────────────────────────────
-- (sin require — el plugin se invoca como previewer y via keybind)

-- ─────────────────────────────────────────────────────────────
--  [12] ouch — Preview y compresión de archivos comprimidos
--  Repo:    ndtoan96/ouch  (ya pkg add ndtoan96/ouch)
--  Dep:     ouch (sudo pacman -S ouch)
--  setup(): NO — previewer via yazi.toml + keybind para comprimir
--  Keybind: C → plugin ouch (comprimir selección)
--  Preview: zip, tar, bzip2, 7z, rar, xz, zstd, jar — automático
-- ─────────────────────────────────────────────────────────────
-- (sin require — previewer puro + invocado on-demand via keybind)

-- ─────────────────────────────────────────────────────────────
--  [13] what-size — Calcula tamaño de selección o directorio actual
--  Repo:    pirafrank/what-size  (ya pkg add pirafrank/what-size)
--  Deps:    ninguna (Yazi 25.5.28+)
--  setup(): YES (opcional — personaliza decoradores del output)
--  Keybind: <C-s> → plugin what-size
-- ─────────────────────────────────────────────────────────────
require("what-size"):setup({})

-- ─────────────────────────────────────────────────────────────
--  [14] lazygit — Abre lazygit en el directorio actual
--  Repo:    Lil-Dank/lazygit  (ya pkg add Lil-Dank/lazygit)
--  Dep:     lazygit en PATH
--  setup(): NO — keybind only
--  Keybind: g,i → plugin lazygit
-- ─────────────────────────────────────────────────────────────
-- (sin require — invocado on-demand via keybind)

-- ─────────────────────────────────────────────────────────────
--  [16] git — Estado git por archivo en el linemode (M, A, ?, !, D...)
--  Repo:    yazi-rs/plugins:git  (ya pkg add yazi-rs/plugins:git)
--  Dep:     git
--  setup(): YES — más los fetchers `git` en yazi.toml [plugin]
--  order:   1500 — posición del signo dentro del linemode
-- ─────────────────────────────────────────────────────────────
require("git"):setup({ order = 1500 })

-- ─────────────────────────────────────────────────────────────
--  [15] recycle-bin — Papelera de reciclaje via trash-cli
--  Repo:    uhs-robert/recycle-bin  (ya pkg add uhs-robert/recycle-bin)
--  Dep:     trash-cli (sudo pacman -S trash-cli)
--  setup(): YES — requerido
--  Keybind: R,b menú | R,o abrir | R,r restaurar | R,d eliminar | R,e vaciar
-- ─────────────────────────────────────────────────────────────
if ya.uid then
	require("recycle-bin"):setup()
end

-- ─────────────────────────────────────────────────────────────
--  [17] toggle-pane — Maximizar/ocultar el panel de preview
--  Repo:    yazi-rs/plugins:toggle-pane  (ya pkg add yazi-rs/plugins:toggle-pane)
--  setup(): NO — keybind only
--  Keybind: <A-p> max-preview | <A-P> min-preview
-- ─────────────────────────────────────────────────────────────
-- (sin require — invocado on-demand via keybind)

-- ─────────────────────────────────────────────────────────────
--  [18] chmod — Cambiar permisos de los archivos seleccionados
--  Repo:    yazi-rs/plugins:chmod  (ya pkg add yazi-rs/plugins:chmod)
--  setup(): NO — keybind only
--  Keybind: c,m → pide el modo (ej: 755, +x) en un input
-- ─────────────────────────────────────────────────────────────
-- (sin require — invocado on-demand via keybind)

-- ─────────────────────────────────────────────────────────────
--  [19] ouch-extract — Extracción con prompt de contraseña (plugin local)
--  Ruta:    plugins/ouch-extract.yazi/ (versionado, no viene de ya pkg)
--  Dep:     ouch >= 0.8 (contraseña vía OUCH_PASSWORD)
--  setup(): NO — lo invoca el opener `extract` de yazi.toml
-- ─────────────────────────────────────────────────────────────
-- (sin require — invocado vía `ya emit plugin ouch-extract`)


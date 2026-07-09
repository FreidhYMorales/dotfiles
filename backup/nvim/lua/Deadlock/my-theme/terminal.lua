local M = {}

local SEQUENCES       = vim.fn.expand("~/.local/state/caelestia/sequences.txt")
local KITTY_CONF      = vim.fn.expand("~/.config/kitty/kitty.conf")
local OMARCHY_THEME   = vim.fn.expand("~/.config/omarchy/current/theme.name")

local function lighten(hex, n)
	local r = math.min(255, tonumber(hex:sub(2, 3), 16) + n)
	local g = math.min(255, tonumber(hex:sub(4, 5), 16) + n)
	local b = math.min(255, tonumber(hex:sub(6, 7), 16) + n)
	return string.format("#%02x%02x%02x", r, g, b)
end

local function build(tc)
	local bg = tc.bg
	return {
		standardWhite          = "#ffffff",
		standardBlack          = "#000000",

		mainText               = tc.fg,
		emphasisText           = tc[15] or "#ffffff",
		commandText            = tc[15] or "#ffffff",
		inactiveText           = tc[8],
		disabledText           = tc[8],
		lineNumberText         = tc[8],
		selectedText           = tc[15] or "#ffffff",
		inactiveSelectionText  = tc.fg,
		foregroundEmphasis     = tc[15] or "#ffffff",
		terminalGray           = tc[8],

		syntaxFunction         = tc[14],
		syntaxKeyword          = tc[4],
		specialKeyword         = tc[13],
		lightRed               = tc[1],
		warningEmphasis        = tc[5],
		warningText            = tc[3],
		stringText             = tc[2],
		linkText               = tc[12],
		syntaxLightBlue        = tc[12],
		syntaxBeige            = tc[7],
		syntaxMagenta          = tc[5],
		syntaxOperator         = tc[8],
		commentText            = tc[8],
		syntaxError            = tc[9],
		errorText              = tc[9],
		successText            = tc[10],
		property               = tc[3],

		editorBackground         = bg,
		sidebarBackground        = lighten(bg, 10),
		popupBackground          = lighten(bg, 10),
		floatingWindowBackground = lighten(bg, 25),
		menuOptionBackground     = lighten(bg, 37),
		windowBorder             = lighten(bg, 25),
		focusedBorder            = lighten(bg, 37),
		emphasizedBorder         = lighten(bg, 50),

		is_dark        = true,
		is_transparent = false,
	}
end

-- Parse output of `kitty @ get-colors`:  "name\t#rrggbb\n" per line
local function parse_kitty_ipc(output)
	local c = {}
	for name, hex in output:gmatch("([%w_]+)%s+#(%x%x%x%x%x%x)") do
		local n = name:match("^color(%d+)$")
		if n then
			c[tonumber(n)] = "#" .. hex
		elseif name == "foreground" then
			c.fg = "#" .. hex
		elseif name == "background" then
			c.bg = "#" .. hex
		end
	end
	return c
end

local function parse_caelestia(content)
	local c = {}
	for n, r, g, b in content:gmatch("%]4;(%d+);rgb:(%x%x)/(%x%x)/(%x%x)") do
		c[tonumber(n)] = "#" .. r .. g .. b
	end
	local r, g, b = content:match("%]10;rgb:(%x%x)/(%x%x)/(%x%x)")
	if r then c.fg = "#" .. r .. g .. b end
	r, g, b = content:match("%]11;rgb:(%x%x)/(%x%x)/(%x%x)")
	if r then c.bg = "#" .. r .. g .. b end
	return c
end

local function parse_kitty_conf(path, visited)
	visited = visited or {}
	if visited[path] then return {} end
	visited[path] = true

	local f = io.open(path, "r")
	if not f then return {} end
	local content = f:read("*a")
	f:close()

	local c = {}
	local dir = path:match("^(.*/)") or ""

	for line in content:gmatch("[^\n]+") do
		local inc = line:match("^%s*include%s+(.-)%s*$")
		if inc then
			inc = vim.fn.expand(inc)
			if inc:sub(1, 1) ~= "/" then inc = dir .. inc end
			for k, v in pairs(parse_kitty_conf(inc, visited)) do c[k] = v end
		end

		local n, hex = line:match("^%s*color(%d+)%s+#(%x%x%x%x%x%x)%s*$")
		if n then c[tonumber(n)] = "#" .. hex end

		local fg = line:match("^%s*foreground%s+#(%x%x%x%x%x%x)%s*$")
		if fg then c.fg = "#" .. fg end

		local bg = line:match("^%s*background%s+#(%x%x%x%x%x%x)%s*$")
		if bg then c.bg = "#" .. bg end
	end

	return c
end

-- Returns a value that changes when the terminal theme changes, used for
-- cache invalidation between Neovim sessions.
function M.mtime()
	local stat = vim.uv.fs_stat(OMARCHY_THEME)
	if stat then return stat.mtime.sec end
	stat = vim.uv.fs_stat(SEQUENCES)
	if stat then return stat.mtime.sec end
	stat = vim.uv.fs_stat(KITTY_CONF)
	return stat and stat.mtime.sec or 0
end

function M.load()
	-- 1. kitty IPC — live colors from the running kitty instance
	local output = vim.fn.system("kitty @ get-colors 2>/dev/null")
	if vim.v.shell_error == 0 and output ~= "" then
		local tc = parse_kitty_ipc(output)
		if tc.bg and tc.fg and tc[0] then return build(tc) end
	end

	-- 2. caelestia sequences file (legacy)
	local f = io.open(SEQUENCES, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local tc = parse_caelestia(content)
		if tc.bg and tc.fg and tc[0] then return build(tc) end
	end

	-- 3. kitty.conf parse (offline fallback)
	local tc = parse_kitty_conf(KITTY_CONF)
	if not tc.bg or not tc.fg or not tc[0] then return nil end
	return build(tc)
end

return M

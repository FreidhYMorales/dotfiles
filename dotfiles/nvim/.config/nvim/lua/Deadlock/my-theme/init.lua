local config = require("Deadlock.my-theme.config")
local utils  = require("Deadlock.my-theme.utils")
local theme  = {}

-- These are refreshed in theme.setup() when the variant changes
local colorscheme   = require("Deadlock.my-theme.colorscheme")
local avante        = require("Deadlock.my-theme.integrations.avante")
local barbecue      = require("Deadlock.my-theme.integrations.barbecue")
local blink         = require("Deadlock.my-theme.integrations.blink")
local bufferline    = require("Deadlock.my-theme.integrations.bufferline")
local cmp           = require("Deadlock.my-theme.integrations.cmp")
local gitsigns      = require("Deadlock.my-theme.integrations.gitsigns")
local lsp           = require("Deadlock.my-theme.integrations.lsp")
local noice         = require("Deadlock.my-theme.integrations.noice")
local snacks_hl     = require("Deadlock.my-theme.integrations.snacks")
local todo_comments = require("Deadlock.my-theme.integrations.todo_comments")
local trouble       = require("Deadlock.my-theme.integrations.trouble")
local whichkey      = require("Deadlock.my-theme.integrations.whichkey")

local api = vim.api

-- ---------------------------------------------------------------------------
-- Transparent overlay: called ONLY when the active variant is transparent
-- ---------------------------------------------------------------------------
local function set_background_transparent()
	api.nvim_set_hl(0, "NonText",    { bg = nil, ctermbg = nil })
	api.nvim_set_hl(0, "Normal",     { bg = nil, ctermbg = nil })
	api.nvim_set_hl(0, "NormalNC",   { bg = nil, ctermbg = nil })
	api.nvim_set_hl(0, "SignColumn", { bg = nil, ctermbg = nil, fg = nil, ctermfg = nil })
	api.nvim_set_hl(0, "Pmenu",      { bg = nil, ctermbg = nil, fg = colorscheme.mainText })
	api.nvim_set_hl(0, "FloatBorder",{ bg = nil, ctermbg = nil, fg = colorscheme.emphasisText })
	api.nvim_set_hl(0, "NormalFloat",{ bg = nil, ctermbg = nil, fg = nil, ctermfg = nil })
	api.nvim_set_hl(0, "TabLine",    { bg = nil, ctermbg = nil, fg = nil, ctermfg = nil })
	api.nvim_set_hl(0, "WinBar",     { bg = nil, ctermbg = nil })
	api.nvim_set_hl(0, "WinBarNC",   { bg = nil, ctermbg = nil })
	-- CursorLine color adapts to dark/light transparent variant
	local cursorline_bg = colorscheme.is_dark and "#444444" or "#cccccc"
	api.nvim_set_hl(0, "CursorLine", { bg = cursorline_bg, fg = "NONE", ctermfg = "NONE" })
end

-- ---------------------------------------------------------------------------
-- Terminal colors (16-color palette mapped to Night Wolf syntax tokens)
-- ---------------------------------------------------------------------------
local function set_terminal_colors()
	-- ANSI palette — matches NightWolf terminal.ansi* assignments exactly
	vim.g.terminal_color_0  = colorscheme.is_transparent and "#1a1a1a" or colorscheme.editorBackground
	vim.g.terminal_color_1  = colorscheme.lightRed         -- ansiRed        syntaxRed  #FF7878
	vim.g.terminal_color_2  = colorscheme.successText      -- ansiGreen      syntaxGreen #AAE682
	vim.g.terminal_color_3  = colorscheme.warningText      -- ansiYellow     syntaxYellow #FFDC96
	vim.g.terminal_color_4  = colorscheme.linkText         -- ansiBlue       syntaxBlue  #00B1FF
	vim.g.terminal_color_5  = colorscheme.syntaxMagenta    -- ansiMagenta    syntaxMagenta #FF50FF
	vim.g.terminal_color_6  = colorscheme.syntaxFunction   -- ansiCyan       syntaxCyan  #00DCDC
	vim.g.terminal_color_7  = colorscheme.mainText         -- ansiWhite      text        #C8C8C8
	vim.g.terminal_color_8  = colorscheme.inactiveText     -- ansiBrightBlack principal_4 #787878
	vim.g.terminal_color_9  = colorscheme.lightRed         -- ansiBrightRed  (same as normal)
	vim.g.terminal_color_10 = colorscheme.successText      -- ansiBrightGreen (same)
	vim.g.terminal_color_11 = colorscheme.warningText      -- ansiBrightYellow (same)
	vim.g.terminal_color_12 = colorscheme.linkText         -- ansiBrightBlue  (same)
	vim.g.terminal_color_13 = colorscheme.syntaxMagenta    -- ansiBrightMagenta (same)
	vim.g.terminal_color_14 = colorscheme.syntaxFunction   -- ansiBrightCyan  (same)
	vim.g.terminal_color_15 = colorscheme.emphasisText     -- ansiBrightWhite white #FFFFFF
	vim.g.terminal_color_background = colorscheme.is_transparent and "#1a1a1a" or colorscheme.editorBackground
	vim.g.terminal_color_foreground = colorscheme.mainText
end

-- ---------------------------------------------------------------------------
-- Cache helpers
-- ---------------------------------------------------------------------------

local CACHE_DIR = vim.fn.stdpath("cache") .. "/my-theme"

local function fingerprint()
	local cfg = require("Deadlock.my-theme.config")
	local it  = cfg.italics or {}
	local fp  = string.format("v=%s,ic=%s,ik=%s,if=%s,is=%s,iv=%s",
		cfg.variant or "default",
		tostring(it.comments),  tostring(it.keywords),
		tostring(it.functions), tostring(it.strings), tostring(it.variables))
	if cfg.variant == "terminal" then
		local ok, terminal_mod = pcall(require, "Deadlock.my-theme.terminal")
		if ok then fp = fp .. ",mt=" .. terminal_mod.mtime() end
	end
	return fp
end

local function cache_path()
	local cfg = require("Deadlock.my-theme.config")
	return CACHE_DIR .. "/" .. (cfg.variant or "default") .. ".luac"
end

local function serialize_hl(opts)
	local parts = {}
	for k, v in pairs(opts) do
		if type(v) == "string" then
			table.insert(parts, k .. "=" .. string.format("%q", v))
		elseif type(v) == "boolean" and v then
			table.insert(parts, k .. "=true")
		elseif type(v) == "number" then
			table.insert(parts, k .. "=" .. tostring(v))
		end
	end
	table.sort(parts)
	return "{" .. table.concat(parts, ",") .. "}"
end

local function write_cache(groups)
	vim.fn.mkdir(CACHE_DIR, "p")
	local lines = { "local a=vim.api.nvim_set_hl" }
	for group, opts in pairs(groups) do
		table.insert(lines, string.format("a(0,%q,%s)", group, serialize_hl(opts)))
	end
	local source = table.concat(lines, "\n")
	local fn, err = load(source)
	if not fn then
		vim.notify("my-theme: cache compile error: " .. tostring(err), vim.log.levels.WARN, { title = "my-theme" })
		return
	end
	local bc = io.open(cache_path(), "wb")
	if bc then bc:write(string.dump(fn)); bc:close() end
	local fp = io.open(cache_path() .. ".fp", "w")
	if fp then fp:write(fingerprint()); fp:close() end
end

local function load_cache()
	local fp = io.open(cache_path() .. ".fp", "r")
	if not fp then return false end
	local stored = fp:read("*l"); fp:close()
	if stored ~= fingerprint() then return false end
	local fn = loadfile(cache_path())
	if not fn then return false end
	return pcall(fn)
end

-- ---------------------------------------------------------------------------
-- Build highlight groups table (returns table, does NOT apply)
-- ---------------------------------------------------------------------------
local function build_groups()
	local bg = colorscheme.is_transparent and "NONE" or colorscheme.editorBackground

	local diff_add    = utils.shade(colorscheme.successText,    0.5, colorscheme.editorBackground)
	local diff_delete = utils.shade(colorscheme.syntaxError,    0.5, colorscheme.editorBackground)
	local diff_change = utils.shade(colorscheme.syntaxFunction, 0.5, colorscheme.editorBackground)
	local diff_text   = utils.shade(colorscheme.warningEmphasis,0.5, colorscheme.editorBackground)

	local groups = {
		-- -----------------------------------------------------------------------
		-- Base
		-- -----------------------------------------------------------------------
		Normal      = { fg = colorscheme.mainText, bg = bg },
		LineNr      = { fg = colorscheme.lineNumberText },
		ColorColumn = { bg = utils.shade(colorscheme.linkText, 0.5, colorscheme.editorBackground) },
		Conceal     = {},
		Cursor      = { fg = colorscheme.editorBackground ~= "none" and colorscheme.editorBackground or "#000000", bg = colorscheme.mainText },
		lCursor     = { link = "Cursor" },
		CursorIM    = { link = "Cursor" },
		CursorLine  = { bg = colorscheme.popupBackground },
		CursorColumn = { link = "CursorLine" },
		Directory   = { fg = colorscheme.syntaxFunction },

		DiffAdd    = { bg = bg, fg = diff_add },
		DiffChange = { bg = bg, fg = diff_change },
		DiffDelete = { bg = bg, fg = diff_delete },
		DiffText   = { bg = bg, fg = diff_text },

		EndOfBuffer = { fg = colorscheme.syntaxKeyword },
		TermCursor  = { link = "Cursor" },
		TermCursorNC = { link = "Cursor" },
		ErrorMsg    = { fg = colorscheme.syntaxError },
		VertSplit   = { fg = colorscheme.windowBorder, bg = bg },
		Winseparator = { link = "VertSplit" },
		SignColumn  = { link = "Normal" },
		Folded      = { fg = colorscheme.mainText, bg = colorscheme.popupBackground },
		FoldColumn  = { link = "SignColumn" },

		IncSearch   = {
			bg = utils.mix(colorscheme.syntaxFunction, colorscheme.editorBackground ~= "none" and colorscheme.editorBackground or "#000000", 0.30),
			fg = colorscheme.emphasisText,
		},
		Substitute  = { link = "IncSearch" },
		CursorLineNr = { fg = colorscheme.commentText },
		MatchParen  = { fg = colorscheme.syntaxError, bg = bg },
		ModeMsg     = { link = "Normal" },
		MsgArea     = { link = "Normal" },
		MoreMsg     = { fg = colorscheme.syntaxFunction },
		NonText     = { fg = utils.shade(colorscheme.mainText, 0.20, colorscheme.editorBackground) },
		NormalFloat = { bg = colorscheme.floatingWindowBackground },
		FloatBorder = { fg = colorscheme.emphasisText, bg = colorscheme.floatingWindowBackground },
		NormalNC    = { link = "Normal" },

		Question    = { fg = colorscheme.syntaxFunction },
		QuickFixLine = { fg = colorscheme.syntaxFunction },
		SpecialKey  = { fg = colorscheme.syntaxOperator },

		StatusLine   = { fg = colorscheme.mainText, bg = bg },
		StatusLineNC = { fg = colorscheme.inactiveText, bg = colorscheme.sidebarBackground },

		TabLine     = { bg = colorscheme.sidebarBackground, fg = colorscheme.inactiveText },
		TabLineFill = { link = "TabLine" },
		TabLineSel  = { bg = colorscheme.editorBackground ~= "none" and colorscheme.editorBackground or colorscheme.sidebarBackground, fg = colorscheme.emphasisText },

		WinBar   = { fg = colorscheme.mainText,     bg = bg },
		WinBarNC = { fg = colorscheme.inactiveText, bg = bg },

		Search    = { bg = utils.shade(colorscheme.stringText, 0.40, colorscheme.editorBackground) },
		SpellBad  = { undercurl = true, sp = colorscheme.syntaxError },
		SpellCap  = { undercurl = true, sp = colorscheme.syntaxFunction },
		SpellLocal = { undercurl = true, sp = colorscheme.syntaxKeyword },
		SpellRare = { undercurl = true, sp = colorscheme.warningText },
		Title     = { fg = colorscheme.syntaxFunction },
		Visual    = { bg = utils.shade(colorscheme.syntaxFunction, 0.40, colorscheme.editorBackground) },
		VisualNOS = { link = "Visual" },
		WarningMsg = { fg = colorscheme.warningText },
		Whitespace = { fg = colorscheme.syntaxOperator },
		WildMenu   = { bg = colorscheme.menuOptionBackground },

		-- -----------------------------------------------------------------------
		-- Syntax — Night Wolf palette
		-- -----------------------------------------------------------------------
		Comment   = { fg = colorscheme.commentText, italic = config.italics.comments or false },

		Constant  = { fg = colorscheme.lightRed },
		String    = { fg = colorscheme.stringText, italic = config.italics.strings or false },
		Character = { fg = colorscheme.warningEmphasis },
		Number    = { fg = colorscheme.warningEmphasis },
		Boolean   = { fg = colorscheme.lightRed },
		Float     = { link = "Number" },

		Identifier = { fg = colorscheme.mainText },
		Function   = { fg = colorscheme.syntaxFunction, bold = true, italic = config.italics.functions or false },
		Method     = { fg = colorscheme.syntaxFunction },
		Property   = { fg = colorscheme.property },
		Field      = { link = "Property" },
		Parameter  = { fg = colorscheme.warningText },

		Statement   = { fg = colorscheme.lightRed },
		Conditional = { fg = colorscheme.specialKeyword },
		Label       = { fg = colorscheme.lightRed },
		Operator    = { fg = colorscheme.lightRed },
		Keyword     = { fg = colorscheme.syntaxKeyword, italic = config.italics.keywords or false },
		Exception   = { fg = colorscheme.lightRed },

		PreProc   = { link = "Keyword" },
		Define    = { fg = colorscheme.syntaxKeyword },
		Macro     = { link = "Define" },
		PreCondit = { fg = colorscheme.lightRed },

		Type    = { fg = colorscheme.specialKeyword },
		Struct  = { link = "Type" },
		Class   = { link = "Type" },

		Attribute   = { link = "Character" },
		Punctuation = { fg = colorscheme.syntaxOperator },
		Special     = { fg = colorscheme.syntaxOperator },
		SpecialChar = { fg = colorscheme.stringText },
		Tag         = { fg = colorscheme.lightRed },
		Delimiter   = { fg = colorscheme.syntaxOperator },
		Debug       = { fg = colorscheme.specialKeyword },

		Underlined = { underline = true },
		Bold       = { bold = true },
		Italic     = { italic = true },
		Ignore     = { fg = bg },
		Error      = { link = "ErrorMsg" },
		Todo       = { fg = colorscheme.warningText, bold = true },

		-- -----------------------------------------------------------------------
		-- Diagnostics
		-- -----------------------------------------------------------------------
		DiagnosticError = { link = "Error" },
		DiagnosticWarn  = { link = "WarningMsg" },
		DiagnosticInfo  = { fg = colorscheme.syntaxFunction },
		DiagnosticHint  = { fg = colorscheme.warningEmphasis },

		DiagnosticVirtualTextError = { link = "DiagnosticError" },
		DiagnosticVirtualTextWarn  = { link = "DiagnosticWarn" },
		DiagnosticVirtualTextInfo  = { link = "DiagnosticInfo" },
		DiagnosticVirtualTextHint  = { link = "DiagnosticHint" },

		DiagnosticUnderlineError = { undercurl = true, sp = colorscheme.syntaxError },
		DiagnosticUnderlineWarn  = { undercurl = true, sp = colorscheme.warningText },
		DiagnosticUnderlineInfo  = { undercurl = true, sp = colorscheme.syntaxFunction },
		DiagnosticUnderlineHint  = { undercurl = true, sp = colorscheme.warningEmphasis },

		-- -----------------------------------------------------------------------
		-- Tree-Sitter  (old @text.* names + modern @markup.* aliases)
		-- -----------------------------------------------------------------------
		["@text"]          = { fg = colorscheme.mainText },
		["@text.literal"]  = { link = "Property" },
		["@text.strong"]   = { link = "Bold" },
		["@text.italic"]   = { link = "Italic" },
		["@text.title"]    = { link = "Keyword" },
		["@text.uri"]      = { fg = colorscheme.syntaxFunction, sp = colorscheme.syntaxFunction, underline = true },
		["@text.underline"]= { link = "Underlined" },
		["@text.todo"]     = { link = "Todo" },
		["@text.diff.add"]    = { fg = colorscheme.successText },
		["@text.diff.delete"] = { fg = colorscheme.errorText },

		["@markup.strong"]              = { link = "Bold" },
		["@markup.italic"]              = { link = "Italic" },
		["@markup.underline"]           = { link = "Underlined" },
		["@markup.strikethrough"]       = { strikethrough = true },

		["@markup.heading"]             = { fg = colorscheme.syntaxKeyword, bold = true },
		["@markup.heading.1"]           = { fg = colorscheme.syntaxKeyword, bold = true },
		["@markup.heading.2"]           = { fg = colorscheme.syntaxKeyword, bold = true },
		["@markup.heading.3"]           = { fg = colorscheme.syntaxKeyword, bold = true },
		["@markup.heading.4"]           = { fg = colorscheme.syntaxKeyword, bold = true },
		["@markup.heading.5"]           = { fg = colorscheme.syntaxKeyword, bold = true },
		["@markup.heading.6"]           = { fg = colorscheme.syntaxKeyword, bold = true },

		["@markup.quote"]               = { fg = colorscheme.stringText, italic = true },

		["@markup.link"]                = { fg = colorscheme.linkText, underline = true },
		["@markup.link.url"]            = { fg = colorscheme.syntaxLightBlue, underline = true },
		["@markup.link.label"]          = { fg = colorscheme.linkText },

		["@markup.list"]                = { fg = colorscheme.warningText },
		["@markup.list.checked"]        = { fg = colorscheme.stringText },
		["@markup.list.unchecked"]      = { fg = colorscheme.warningText },

		["@markup.raw"]                 = { fg = colorscheme.syntaxBeige },
		["@markup.raw.block"]           = { fg = colorscheme.syntaxBeige },

		["@markup.environment"]         = { fg = colorscheme.specialKeyword },

		["@markup.rule"]                = { fg = colorscheme.warningEmphasis },
		["@diff.plus"]          = { fg = colorscheme.successText },
		["@diff.minus"]         = { fg = colorscheme.errorText },
		["@diff.delta"]         = { fg = colorscheme.warningEmphasis },

		["@comment.todo"]       = { link = "Todo" },
		["@comment.note"]       = { fg = colorscheme.syntaxFunction, bold = true },
		["@comment.warning"]    = { link = "WarningMsg" },
		["@comment.error"]      = { link = "ErrorMsg" },

		["@symbol"]   = { fg = colorscheme.syntaxOperator },

		["@comment"]                   = { link = "Comment" },
		["@punctuation"]               = { link = "Punctuation" },
		["@punctuation.bracket"]       = { fg = colorscheme.warningText },
		["@punctuation.delimiter"]     = { fg = colorscheme.syntaxOperator },
		["@punctuation.terminator.statement"] = { link = "Delimiter" },
		["@punctuation.special"]       = { fg = colorscheme.lightRed },
		["@punctuation.separator.keyvalue"] = { fg = colorscheme.syntaxOperator },

		["@constant"]         = { link = "Constant" },
		["@constant.builtin"] = { fg = colorscheme.lightRed },
		["@constant.macro"]   = { link = "Define" },
		["@string"]           = { link = "String" },
		["@string.escape"]    = { fg = colorscheme.stringText },
		["@string.special"]   = { fg = colorscheme.stringText },
		["@string.regexp"]    = { fg = colorscheme.syntaxBeige },
		["@number"]           = { link = "Number" },
		["@number.float"]     = { link = "Number" },
		["@boolean"]          = { link = "Boolean" },

		["@function"]          = { fg = colorscheme.syntaxFunction, bold = true, italic = config.italics.functions or false },
		["@function.call"]     = { fg = colorscheme.syntaxFunction, italic = true },
		["@function.builtin"]  = { fg = colorscheme.syntaxKeyword, italic = true },
		["@function.macro"]    = { fg = colorscheme.syntaxKeyword },
		["@parameter"]         = { link = "Parameter" },
		["@method"]            = { link = "Function" },
		["@method.call"]       = { fg = colorscheme.syntaxFunction, italic = true },
		["@field"]             = { link = "Property" },
		["@property"]          = { link = "Property" },
		["@constructor"]       = {},
		["@label"]             = { link = "Label" },
		["@operator"]          = { fg = colorscheme.lightRed },
		["@exception"]         = { link = "Exception" },

		["@variable"]          = { fg = colorscheme.warningText, italic = config.italics.variables or false },
		["@variable.builtin"]  = { fg = colorscheme.warningEmphasis },
		["@variable.member"]   = { fg = colorscheme.mainText },
		["@variable.parameter"]= { fg = colorscheme.warningText, italic = config.italics.variables or false },

		["@type"]          = { link = "Type" },
		["@type.definition"]= { fg = colorscheme.specialKeyword },
		["@type.builtin"]  = { fg = colorscheme.syntaxKeyword },
		["@type.qualifier"]= { fg = colorscheme.syntaxKeyword },

		["@keyword"]            = { fg = colorscheme.syntaxKeyword, italic = config.italics.keywords or false },
		["@keyword.function"]   = { fg = colorscheme.syntaxKeyword, italic = config.italics.keywords or false },
		["@keyword.storage"]    = { fg = colorscheme.linkText, italic = config.italics.keywords or false },
		["@keyword.import"]     = { fg = colorscheme.linkText, italic = config.italics.keywords or false },
		["@keyword.return"]     = { fg = colorscheme.syntaxKeyword, italic = config.italics.keywords or false },
		["@keyword.conditional"]= { fg = colorscheme.specialKeyword, italic = false },
		["@keyword.loop"]       = { fg = colorscheme.specialKeyword, italic = config.italics.keywords or false },

		["@namespace"]     = { link = "Type" },
		["@module"]        = { link = "Type" },
		["@annotation"]    = { link = "Label" },
		["@debug"]         = { fg = colorscheme.specialKeyword },

		["@tag"]           = { link = "Tag" },
		["@tag.builtin"]   = { link = "Tag" },
		["@tag.delimiter"] = { fg = colorscheme.syntaxOperator },
		["@tag.attribute"] = { fg = colorscheme.syntaxKeyword, italic = true },
		["@tag.jsx.element"]= { fg = colorscheme.lightRed },
		["@attribute"]     = { fg = colorscheme.specialKeyword },
		["@error"]         = { link = "Error" },
		["@warning"]       = { link = "WarningMsg" },
		["@info"]          = { fg = colorscheme.syntaxFunction },

		-- Rainbow delimiters
		RainbowDelimiterYellow  = { fg = colorscheme.warningText },
		RainbowDelimiterRed     = { fg = colorscheme.lightRed },
		RainbowDelimiterBlue    = { fg = colorscheme.linkText },
		RainbowDelimiterOrange  = { fg = colorscheme.warningEmphasis },
		RainbowDelimiterViolet  = { fg = colorscheme.specialKeyword },
		RainbowDelimiterGreen   = { fg = colorscheme.stringText },

		-- Language-specific overrides — Lua
		["@function.call.lua"]              = { fg = colorscheme.mainText },
		["@method.call.lua"]                = { fg = colorscheme.mainText },
		["@function.builtin.lua"]           = { fg = colorscheme.mainText },
		["@lsp.type.function.lua"]          = { fg = colorscheme.mainText },
		["@lsp.type.method.lua"]            = { fg = colorscheme.mainText },
		["@lsp.typemod.function.global.lua"]= { fg = colorscheme.mainText },
		["@lsp.typemod.method.global.lua"]  = { fg = colorscheme.mainText },

		-- Language-specific overrides — JS/TS
		["@variable.builtin.javascript"]  = { fg = colorscheme.lightRed },
		["@variable.builtin.typescript"]  = { fg = colorscheme.lightRed },
		["@variable.builtin.tsx"]         = { fg = colorscheme.lightRed },
		["@variable.builtin.jsx"]         = { fg = colorscheme.lightRed },

		["@keyword.storage.javascript"]   = { fg = colorscheme.linkText, italic = true },
		["@keyword.storage.typescript"]   = { fg = colorscheme.linkText, italic = true },

		-- Language-specific overrides — Go
		["@keyword.go"]                   = { fg = colorscheme.linkText, italic = true },
		["@keyword.import.go"]            = { fg = colorscheme.linkText, italic = true },
		["@keyword.function.go"]          = { fg = colorscheme.linkText, italic = true },
		["@type.builtin.go"]              = { fg = colorscheme.syntaxKeyword },
		["@type.go"]                      = { fg = colorscheme.warningText },
		["@module.go"]                    = { fg = colorscheme.warningText },
		["@constant.builtin.go"]          = { fg = colorscheme.lightRed },
		["@string.special.go"]            = { fg = colorscheme.lightRed },
		["@function.call.go"]             = { fg = colorscheme.syntaxFunction },
		["@function.go"]                  = { fg = colorscheme.syntaxFunction },

		["@label.json"]         = { fg = colorscheme.property },
		["@label.help"]         = { link = "@text.uri" },
		["@text.uri.html"]      = { underline = true },
		["@markup.link.url.html"]= { underline = true },

		-- Language-specific overrides — CSS/SCSS
		["@property.css"]               = { fg = colorscheme.syntaxFunction },
		["@type.css"]                   = { fg = colorscheme.syntaxFunction },
		["@variable.css"]               = { fg = colorscheme.syntaxLightBlue },
		["@variable.scss"]              = { fg = colorscheme.syntaxLightBlue },
		["@string.css"]                 = { fg = colorscheme.warningEmphasis },
		["@number.css"]                 = { fg = colorscheme.warningEmphasis },
		["@tag.css"]                    = { fg = colorscheme.lightRed },
		["@tag.scss"]                   = { fg = colorscheme.lightRed },
		["@attribute.css"]              = { fg = colorscheme.stringText },
		["@attribute.scss"]             = { fg = colorscheme.stringText },
		["@keyword.css"]                = { fg = colorscheme.specialKeyword },
		["@keyword.scss"]               = { fg = colorscheme.syntaxKeyword },
		["@function.scss"]              = { fg = colorscheme.linkText },
		["@punctuation.special.scss"]   = { fg = colorscheme.lightRed },
		["@namespace.css"]              = { fg = colorscheme.warningText },
		["@namespace.scss"]             = { fg = colorscheme.warningText },

		-- -----------------------------------------------------------------------
		-- LSP semantic tokens
		-- -----------------------------------------------------------------------
		["@lsp.type.namespace"]    = { link = "@namespace" },
		["@lsp.type.type"]         = { link = "@type" },
		["@lsp.type.class"]        = { link = "@function" },
		["@lsp.type.enum"]         = { link = "@type" },
		["@lsp.type.enumMember"]   = { fg = colorscheme.lightRed },
		["@lsp.type.interface"]    = { fg = colorscheme.syntaxLightBlue },
		["@lsp.type.struct"]       = { link = "@type" },
		["@lsp.type.parameter"]    = { fg = colorscheme.warningText },
		["@lsp.type.property"]     = { fg = colorscheme.mainText },
		["@lsp.type.function"]     = { link = "@function" },
		["@lsp.type.method"]       = { link = "@method" },
		["@lsp.type.macro"]        = { link = "@label" },
		["@lsp.type.decorator"]    = { link = "@label" },
		["@lsp.type.variable"]     = { link = "@variable" },
		["@lsp.type.keyword"]      = {},
		["@lsp.type.regexp"]       = { fg = colorscheme.syntaxBeige },

		["@lsp.typemod.function.declaration"] = { link = "@function" },
		["@lsp.typemod.function.readonly"]    = { link = "@function" },
		["@lsp.typemod.variable.defaultLibrary"] = { fg = colorscheme.lightRed },
	}

	-- ── Integrations ────────────────────────────────────────────────────────
	groups = vim.tbl_extend("force", groups, avante.highlights())
	groups = vim.tbl_extend("force", groups, barbecue.highlights())
	groups = vim.tbl_extend("force", groups, blink.highlights())
	groups = vim.tbl_extend("force", groups, cmp.highlights())
	groups = vim.tbl_extend("force", groups, gitsigns.highlights())
	groups = vim.tbl_extend("force", groups, lsp.highlights())
	groups = vim.tbl_extend("force", groups, noice.highlights())
	groups = vim.tbl_extend("force", groups, snacks_hl.highlights())
	groups = vim.tbl_extend("force", groups, todo_comments.highlights())
	groups = vim.tbl_extend("force", groups, trouble.highlights())
	groups = vim.tbl_extend("force", groups, whichkey.highlights())

	-- ── Global user overrides ───────────────────────────────────────────────
	groups = vim.tbl_extend("force", groups,
		type(config.overrides) == "function" and config.overrides() or config.overrides)

	-- ── Per-variant polish ──────────────────────────────────────────────────
	local polish = config.polish_hl and config.polish_hl[config.variant]
	if polish then
		groups = vim.tbl_extend("force", groups,
			type(polish) == "function" and polish() or polish)
	end

	return groups
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function theme.setup(values)
	setmetatable(config, { __index = vim.tbl_extend("force", config.defaults, values) })

	-- Re-evaluate all modules with the updated config so the chosen variant
	-- is reflected before build_groups() runs.
	local integration_mods = {
		"Deadlock.my-theme.colorscheme",
		"Deadlock.my-theme.terminal",
		"Deadlock.my-theme.integrations.avante",
		"Deadlock.my-theme.integrations.barbecue",
		"Deadlock.my-theme.integrations.blink",
		"Deadlock.my-theme.integrations.bufferline",
		"Deadlock.my-theme.integrations.cmp",
		"Deadlock.my-theme.integrations.gitsigns",
		"Deadlock.my-theme.integrations.lsp",
		"Deadlock.my-theme.integrations.noice",
		"Deadlock.my-theme.integrations.snacks",
		"Deadlock.my-theme.integrations.todo_comments",
		"Deadlock.my-theme.integrations.trouble",
		"Deadlock.my-theme.integrations.whichkey",
	}
	for _, mod in ipairs(integration_mods) do
		package.loaded[mod] = nil
	end

	colorscheme   = require("Deadlock.my-theme.colorscheme")
	avante        = require("Deadlock.my-theme.integrations.avante")
	barbecue      = require("Deadlock.my-theme.integrations.barbecue")
	blink         = require("Deadlock.my-theme.integrations.blink")
	bufferline    = require("Deadlock.my-theme.integrations.bufferline")
	cmp           = require("Deadlock.my-theme.integrations.cmp")
	gitsigns      = require("Deadlock.my-theme.integrations.gitsigns")
	lsp           = require("Deadlock.my-theme.integrations.lsp")
	noice         = require("Deadlock.my-theme.integrations.noice")
	snacks_hl     = require("Deadlock.my-theme.integrations.snacks")
	todo_comments = require("Deadlock.my-theme.integrations.todo_comments")
	trouble       = require("Deadlock.my-theme.integrations.trouble")
	whichkey      = require("Deadlock.my-theme.integrations.whichkey")

	theme.bufferline = { highlights = bufferline.highlights(config) }
end

function theme.colorscheme()
	if vim.version().minor < 8 then
		vim.notify("Neovim 0.8+ is required for my-theme", vim.log.levels.ERROR, { title = "my-theme" })
		return
	end

	vim.api.nvim_command("hi clear")
	if vim.fn.exists("syntax_on") then
		vim.api.nvim_command("syntax reset")
	end

	-- Set vim.o.background so utilities like shade() behave correctly
	vim.o.background = colorscheme.is_dark and "dark" or "light"

	vim.g.VM_theme_set_by_colorscheme = true
	vim.o.termguicolors = true
	vim.g.colors_name = "my-theme"

	set_terminal_colors()

	-- Try compiled cache first; on miss, build → apply → write cache
	if not load_cache() then
		local groups = build_groups()
		for group, opts in pairs(groups) do
			api.nvim_set_hl(0, group, opts)
		end
		write_cache(groups)
	end

	-- FloatBorder must not be a link so it always renders correctly
	api.nvim_set_hl(0, "FloatBorder", { fg = colorscheme.emphasisText, bg = colorscheme.floatingWindowBackground })

	-- Transparent overlay applied ONLY for transparent variants
	if colorscheme.is_transparent then
		set_background_transparent()
	end

	-- Notify listeners that the theme has been (re)loaded
	vim.api.nvim_exec_autocmds("User", { pattern = "NightWolfReload" })
end

return theme

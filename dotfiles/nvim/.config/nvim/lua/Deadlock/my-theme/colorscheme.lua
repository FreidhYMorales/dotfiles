local config = require("Deadlock.my-theme.config")

-- ============================================================================
-- Night Wolf dark syntax palette  (shared across all dark variants)
-- Ref: NightWolfTheme/source/colors/dark-colors.js
-- ============================================================================
local dark = {
	standardWhite = "#ffffff",
	standardBlack = "#000000",

	-- Text scale
	mainText = "#c8c8c8", -- text  rgb(200,200,200)
	emphasisText = "#ffffff",
	commandText = "#ffffff",
	inactiveText = "#787878", -- principal_4 (black variant)
	disabledText = "#969696", -- principal_5
	lineNumberText = "#969696", -- principal_5
	selectedText = "#ffffff",
	inactiveSelectionText = "#c8c8c8",

	-- Syntax  — exact NightWolf hex values
	syntaxFunction = "#00dcdc", -- syntaxCyan      rgb(0,220,220)
	syntaxKeyword = "#9696ff", -- syntaxViolet    rgb(150,150,255)   specialWordB
	specialKeyword = "#dc8cff", -- syntaxPurple    rgb(220,140,255)   specialWordC
	lightRed = "#ff7878", -- syntaxRed       rgb(255,120,120)   contrastText / operator / boolean
	warningEmphasis = "#ffb482", -- syntaxOrange    rgb(255,180,130)   number / variableInstance
	warningText = "#ffdc96", -- syntaxYellow    rgb(255,220,150)   variable declarations / punctuation brackets
	stringText = "#aae682", -- syntaxGreen     rgb(170,230,130)   string
	linkText = "#00b1ff", -- syntaxBlue      rgb(0,177,255)     specialWordA
	commentText = "#647882", -- comment         rgb(100,120,130)
	syntaxError = "#f05050", -- danger          rgb(240,80,80)
	errorText = "#f05050",
	successText = "#aae682", -- syntaxGreen (used for diff-add, success states)
	syntaxOperator = "#c8c8c8", -- text color (punctuation / delimiters stay muted)
	foregroundEmphasis = "#ffffff",
	terminalGray = "#787878",
	property = "#ffdc96", -- syntaxYellow    rgb(255,220,150)   fields / properties
	syntaxBeige = "#dbd4ba", -- syntaxBeige     rgb(219,212,186)   regex
	syntaxLightBlue = "#86e0f4", -- syntaxLightBlue rgb(134,224,244)   CSS variableName
	syntaxMagenta = "#ff50ff", -- syntaxMagenta   rgb(255,80,255)    terminal ANSI magenta
}

-- ============================================================================
-- Light syntax palette
-- ============================================================================
local light = {
	standardWhite = "#ffffff",
	standardBlack = "#000000",

	mainText = "#616161",
	emphasisText = "#212121",
	commandText = "#333333",
	inactiveText = "#9e9e9e",
	disabledText = "#d0d0d0",
	lineNumberText = "#a1a1a1",
	selectedText = "#424242",
	inactiveSelectionText = "#757575",

	syntaxFunction = "#6871ff",
	syntaxKeyword = "#9966cc",
	specialKeyword = "#800080",
	lightRed = "#d7005f",
	warningEmphasis = "#cd9731",
	warningText = "#f29718",
	stringText = "#dd8500",
	linkText = "#1976d2",
	commentText = "#848484",
	syntaxError = "#d6656a",
	errorText = "#d32f2f",
	successText = "#22863a",
	syntaxOperator = "#a1a1a1",
	foregroundEmphasis = "#000000",
	terminalGray = "#333333",
	property = "#af8700", -- fields/properties (amarillo cálido sobre blanco)

	-- Tokens presentes en dark pero ausentes en light — añadidos para evitar
	-- nil references en highlight groups del tema (variantes light/light_transparent).
	syntaxLightBlue = "#0070ba", -- CSS vars, interfaces LSP  (azul medio, ratio 4.5:1 sobre #fff)
	syntaxBeige = "#7a6a4f", -- regex literals            (marrón cálido, ratio 4.6:1)
	syntaxMagenta = "#b800b8", -- ANSI terminal magenta     (magenta puro, ratio 5.1:1)
}

-- ============================================================================
-- Background / chrome scales per variant
--
-- NightWolf defines a principal_0…principal_3 scale per variant:
--   editorBg        → principal         (interBackground)
--   sidebarBg       → principal_0       (panels/sidebar)
--   popupBg         → principal_0       (CursorLine, folded)
--   floatingWinBg   → principal_1       (interBorder — popup/hover windows)
--   menuOptionBg    → principal_2       (selected-item background)
--   windowBorder    → principal_1       (interBorder)
--   focusedBorder   → principal_2
--   emphasizedBorder→ principal_3
--
-- Ref: NightWolfTheme/source/variants/dark/{black,dark-gray,gray,dark-blue}.js
-- ============================================================================
local variants = {
	-- -------------------------------------------------------------------------
	-- Dark transparent  (Night Wolf palette, transparent terminal background)
	-- Uses the "black" principal scale for chrome colors.
	-- -------------------------------------------------------------------------
	default = {
		editorBackground = "none",
		sidebarBackground = "#141414", -- principal_0 (black)
		popupBackground = "#141414",
		floatingWindowBackground = "#282828", -- principal_1 (black)
		menuOptionBackground = "#3c3c3c", -- principal_2 (black)
		windowBorder = "#282828", -- principal_1
		focusedBorder = "#3c3c3c", -- principal_2
		emphasizedBorder = "#505050", -- principal_3
		is_dark = true,
		is_transparent = true,
	},

	-- -------------------------------------------------------------------------
	-- Pure black  —  NightWolf "black" variant
	-- principal:   rgb(0,0,0)     #000000
	-- principal_0: rgb(20,20,20)  #141414
	-- principal_1: rgb(40,40,40)  #282828
	-- principal_2: rgb(60,60,60)  #3c3c3c
	-- principal_3: rgb(80,80,80)  #505050
	-- -------------------------------------------------------------------------
	black = {
		editorBackground = "#0a0a0a",
		sidebarBackground = "#141414",
		popupBackground = "#141414",
		floatingWindowBackground = "#282828",
		menuOptionBackground = "#3c3c3c",
		windowBorder = "#282828",
		focusedBorder = "#3c3c3c",
		emphasizedBorder = "#505050",
		is_dark = true,
		is_transparent = false,
	},

	-- -------------------------------------------------------------------------
	-- Dark gray  —  NightWolf "dark-gray" variant
	-- principal:   rgb(27,27,27)   #1b1b1b
	-- principal_0: rgb(36,36,36)   #242424
	-- principal_1: rgb(46,46,46)   #2e2e2e
	-- principal_2: rgb(61,61,61)   #3d3d3d
	-- principal_3: rgb(82,82,82)   #525252
	-- text:        rgb(206,206,206)#cecece
	-- -------------------------------------------------------------------------
	dark = {
		editorBackground = "#1b1b1b",
		sidebarBackground = "#242424",
		popupBackground = "#242424",
		floatingWindowBackground = "#2e2e2e",
		menuOptionBackground = "#3d3d3d",
		windowBorder = "#2e2e2e",
		focusedBorder = "#3d3d3d",
		emphasizedBorder = "#525252",
		is_dark = true,
		is_transparent = false,
		-- Slightly lighter text for this variant
		mainText = "#cecece",
		inactiveText = "#7c7c7c",
		lineNumberText = "#9d9d9d",
		disabledText = "#9d9d9d",
	},

	-- -------------------------------------------------------------------------
	-- Gray  —  NightWolf "gray" variant
	-- principal:   rgb(37,37,37)  #252525
	-- principal_0: rgb(45,45,45)  #2d2d2d
	-- principal_1: rgb(55,55,55)  #373737
	-- principal_2: rgb(69,69,69)  #454545
	-- principal_3: rgb(89,89,89)  #595959
	-- text:        rgb(206,206,206)#cecece
	-- -------------------------------------------------------------------------
	darker = {
		editorBackground = "#252525",
		sidebarBackground = "#2d2d2d",
		popupBackground = "#2d2d2d",
		floatingWindowBackground = "#373737",
		menuOptionBackground = "#454545",
		windowBorder = "#373737",
		focusedBorder = "#454545",
		emphasizedBorder = "#595959",
		is_dark = true,
		is_transparent = false,
		mainText = "#cecece",
		inactiveText = "#757575",
		lineNumberText = "#9b9b9b",
		disabledText = "#9b9b9b",
	},

	-- -------------------------------------------------------------------------
	-- Dark blue  —  NightWolf "dark-blue" variant
	-- principal:   rgb(16,30,44)   #101e2c
	-- principal_0: rgb(20,40,60)   #14283c
	-- principal_1: rgb(27,50,74)   #1b324a
	-- principal_2: rgb(30,70,103)  #1e4667
	-- principal_3: rgb(48,90,132)  #305a84
	-- text:        rgb(189,210,231)#bdd2e7
	-- -------------------------------------------------------------------------
	dark_blue = {
		editorBackground = "#101e2c",
		sidebarBackground = "#14283c",
		popupBackground = "#14283c",
		floatingWindowBackground = "#1b324a",
		menuOptionBackground = "#1e4667",
		windowBorder = "#1b324a",
		focusedBorder = "#1e4667",
		emphasizedBorder = "#305a84",
		is_dark = true,
		is_transparent = false,
		mainText = "#bdd2e7",
		inactiveText = "#5f82a5",
		lineNumberText = "#7ba5cf",
		disabledText = "#7ba5cf",
	},

	-- -------------------------------------------------------------------------
	-- Light solid
	-- -------------------------------------------------------------------------
	light = {
		editorBackground = "#ffffff",
		sidebarBackground = "#dddddd",
		popupBackground = "#f6f6f6",
		floatingWindowBackground = "#e0e0e0",
		menuOptionBackground = "#ededed",
		windowBorder = "#c2c3c5",
		focusedBorder = "#aaaaaa",
		emphasizedBorder = "#999999",
		is_dark = false,
		is_transparent = false,
	},

	-- -------------------------------------------------------------------------
	-- Light transparent
	-- -------------------------------------------------------------------------
	light_transparent = {
		editorBackground = "none",
		sidebarBackground = "#dddddd",
		popupBackground = "#f6f6f6",
		floatingWindowBackground = "#e0e0e0",
		menuOptionBackground = "#ededed",
		windowBorder = "#c2c3c5",
		focusedBorder = "#aaaaaa",
		emphasizedBorder = "#999999",
		is_dark = false,
		is_transparent = true,
	},
}

-- ============================================================================
-- Build colorscheme table for the active variant
-- ============================================================================

-- Terminal variant: read colors live from caelestia sequences file
if config.variant == "terminal" then
	local ok, terminal_mod = pcall(require, "Deadlock.my-theme.terminal")
	if ok then
		local tc = terminal_mod.load()
		if tc then return tc end
	end
	-- Caelestia file unavailable — fall through to "default"
end

local v = variants[config.variant] or variants["default"]
local syntax = v.is_dark and dark or light

-- Merge: syntax base → variant overrides (allows per-variant text tweaks)
local colorscheme = vim.tbl_extend("force", syntax, {
	editorBackground = v.editorBackground,
	sidebarBackground = v.sidebarBackground,
	popupBackground = v.popupBackground,
	floatingWindowBackground = v.floatingWindowBackground,
	menuOptionBackground = v.menuOptionBackground,
	windowBorder = v.windowBorder,
	focusedBorder = v.focusedBorder,
	emphasizedBorder = v.emphasizedBorder,
	is_transparent = v.is_transparent,
	is_dark = v.is_dark,
})

-- Apply per-variant text overrides (dark, darker, dark_blue have slightly different text shades)
if v.mainText then
	colorscheme.mainText = v.mainText
end
if v.inactiveText then
	colorscheme.inactiveText = v.inactiveText
end
if v.lineNumberText then
	colorscheme.lineNumberText = v.lineNumberText
end
if v.disabledText then
	colorscheme.disabledText = v.disabledText
end

return colorscheme

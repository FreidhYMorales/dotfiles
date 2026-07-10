local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	local float_bg = colorscheme.floatingWindowBackground
	local sidebar_bg = colorscheme.sidebarBackground
	local bg = colorscheme.is_transparent and "NONE" or colorscheme.editorBackground

	return {
		-- ── Notifier ───────────────────────────────────────────────────────────────
		SnacksNotifierError   = { fg = colorscheme.mainText,    bg = float_bg },
		SnacksNotifierWarn    = { fg = colorscheme.mainText,    bg = float_bg },
		SnacksNotifierInfo    = { fg = colorscheme.mainText,    bg = float_bg },
		SnacksNotifierDebug   = { fg = colorscheme.mainText,    bg = float_bg },
		SnacksNotifierTrace   = { fg = colorscheme.inactiveText, bg = float_bg },

		SnacksNotifierBorderError = { fg = colorscheme.syntaxError,     bg = float_bg },
		SnacksNotifierBorderWarn  = { fg = colorscheme.warningEmphasis, bg = float_bg },
		SnacksNotifierBorderInfo  = { fg = colorscheme.syntaxFunction,  bg = float_bg },
		SnacksNotifierBorderDebug = { fg = colorscheme.commentText,     bg = float_bg },
		SnacksNotifierBorderTrace = { fg = colorscheme.inactiveText,    bg = float_bg },

		SnacksNotifierIconError = { fg = colorscheme.syntaxError },
		SnacksNotifierIconWarn  = { fg = colorscheme.warningEmphasis },
		SnacksNotifierIconInfo  = { fg = colorscheme.syntaxFunction },
		SnacksNotifierIconDebug = { fg = colorscheme.commentText },
		SnacksNotifierIconTrace = { fg = colorscheme.inactiveText },

		SnacksNotifierTitleError = { fg = colorscheme.syntaxError,     bold = true },
		SnacksNotifierTitleWarn  = { fg = colorscheme.warningEmphasis, bold = true },
		SnacksNotifierTitleInfo  = { fg = colorscheme.syntaxFunction,  bold = true },
		SnacksNotifierTitleDebug = { fg = colorscheme.commentText,     bold = true },
		SnacksNotifierTitleTrace = { fg = colorscheme.inactiveText,    bold = true },

		-- ── Dashboard ──────────────────────────────────────────────────────────────
		SnacksDashboardNormal  = { fg = colorscheme.mainText,      bg = bg },
		SnacksDashboardDesc    = { fg = colorscheme.mainText },
		SnacksDashboardDir     = { fg = colorscheme.commentText },
		SnacksDashboardFile    = { fg = colorscheme.mainText },
		SnacksDashboardFooter  = { fg = colorscheme.commentText,   italic = true },
		SnacksDashboardHeader  = { fg = colorscheme.syntaxKeyword, bold = true },
		SnacksDashboardIcon    = { fg = colorscheme.syntaxFunction },
		SnacksDashboardKey     = { fg = colorscheme.warningText,   bold = true },
		SnacksDashboardSpecial = { fg = colorscheme.specialKeyword },
		SnacksDashboardTitle   = { fg = colorscheme.emphasisText,  bold = true },

		-- ── Picker ─────────────────────────────────────────────────────────────────
		SnacksPickerTitle        = { fg = colorscheme.emphasisText,  bg = float_bg, bold = true },
		SnacksPickerBorder       = { fg = colorscheme.emphasisText,  bg = float_bg },
		SnacksPickerPreviewTitle = { fg = colorscheme.syntaxFunction, bg = float_bg, bold = true },
		SnacksPickerInputTitle   = { fg = colorscheme.warningText,   bg = float_bg, bold = true },
		SnacksPickerMatch        = { fg = colorscheme.linkText,      bold = true },
		SnacksPickerListCursorLine = { bg = colorscheme.menuOptionBackground },
		SnacksPickerPreviewCursorLine = { bg = colorscheme.menuOptionBackground },

		-- ── Indent guides ──────────────────────────────────────────────────────────
		SnacksIndent      = { fg = colorscheme.windowBorder },
		SnacksIndentScope = { fg = colorscheme.syntaxFunction },

		-- ── Input ──────────────────────────────────────────────────────────────────
		SnacksInput       = { fg = colorscheme.mainText,     bg = float_bg },
		SnacksInputBorder = { fg = colorscheme.emphasisText, bg = float_bg },
		SnacksInputTitle  = { fg = colorscheme.emphasisText, bg = float_bg, bold = true },

		-- ── Profiler / debug ───────────────────────────────────────────────────────
		SnacksProfilerBadge = { fg = colorscheme.standardBlack, bg = colorscheme.syntaxFunction, bold = true },
	}
end

return M

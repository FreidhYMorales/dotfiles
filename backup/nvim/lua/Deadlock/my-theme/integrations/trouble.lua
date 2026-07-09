local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	local bg = colorscheme.is_transparent and "NONE" or colorscheme.editorBackground
	return {
		-- Window base
		TroubleNormal   = { fg = colorscheme.mainText,    bg = bg },
		TroubleNormalNC = { fg = colorscheme.mainText,    bg = bg },
		TroubleBasename = { fg = colorscheme.emphasisText, bold = true },

		-- Text slots
		TroubleText      = { fg = colorscheme.mainText },
		TroublePos       = { fg = colorscheme.commentText },
		TroubleSource    = { fg = colorscheme.commentText,  italic = true },
		TroubleCode      = { fg = colorscheme.inactiveText, italic = true },
		TroubleCount     = { fg = colorscheme.syntaxFunction, bold = true },
		TroubleDirectory = { fg = colorscheme.linkText },
		TroubleFileName  = { fg = colorscheme.mainText },

		-- Indent / structure
		TroubleIndent       = { fg = colorscheme.windowBorder },
		TroubleIndentFold   = { fg = colorscheme.windowBorder },
		TroubleIndentTop    = { fg = colorscheme.windowBorder },
		TroubleIndentMiddle = { fg = colorscheme.windowBorder },
		TroubleIndentLast   = { fg = colorscheme.windowBorder },
		TroubleIndentWs     = { fg = colorscheme.windowBorder },

		-- Severity icons (sign column)
		TroubleIconError   = { fg = colorscheme.syntaxError },
		TroubleIconWarn    = { fg = colorscheme.warningEmphasis },
		TroubleIconInfo    = { fg = colorscheme.syntaxFunction },
		TroubleIconHint    = { fg = colorscheme.successText },
		TroubleIconOther   = { fg = colorscheme.inactiveText },

		-- Sign column severity text
		TroubleSignError   = { fg = colorscheme.syntaxError },
		TroubleSignWarn    = { fg = colorscheme.warningEmphasis },
		TroubleSignInfo    = { fg = colorscheme.syntaxFunction },
		TroubleSignHint    = { fg = colorscheme.successText },
		TroubleSignOther   = { fg = colorscheme.inactiveText },

		-- Preview window
		TroublePreview     = { fg = colorscheme.mainText, bg = colorscheme.floatingWindowBackground },
	}
end

return M

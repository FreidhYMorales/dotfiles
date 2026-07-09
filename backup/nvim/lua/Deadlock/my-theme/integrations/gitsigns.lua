local colorscheme = require("Deadlock.my-theme.colorscheme")
local utils        = require("Deadlock.my-theme.utils")

local M = {}

function M.highlights()
	local bg = colorscheme.is_transparent and "NONE" or colorscheme.editorBackground
	return {
		-- Sign column indicators
		GitSignsAdd            = { fg = colorscheme.successText },
		GitSignsChange         = { fg = colorscheme.syntaxFunction },
		GitSignsDelete         = { fg = colorscheme.syntaxError },
		GitSignsTopDelete      = { fg = colorscheme.syntaxError },
		GitSignsChangeDelete   = { fg = colorscheme.warningEmphasis },
		GitSignsUntracked      = { fg = colorscheme.commentText },

		-- Line number column
		GitSignsAddNr          = { fg = colorscheme.successText },
		GitSignsChangeNr       = { fg = colorscheme.syntaxFunction },
		GitSignsDeleteNr       = { fg = colorscheme.syntaxError },
		GitSignsTopDeleteNr    = { fg = colorscheme.syntaxError },
		GitSignsChangeDeleteNr = { fg = colorscheme.warningEmphasis },
		GitSignsUntrackedNr    = { fg = colorscheme.commentText },

		-- Line highlights (used for preview/diff hunks)
		GitSignsAddLn          = { bg = utils.shade(colorscheme.successText,    0.12, colorscheme.editorBackground) },
		GitSignsChangeLn       = { bg = utils.shade(colorscheme.syntaxFunction, 0.12, colorscheme.editorBackground) },
		GitSignsDeleteLn       = { bg = utils.shade(colorscheme.syntaxError,    0.12, colorscheme.editorBackground) },
		GitSignsUntrackedLn    = { bg = utils.shade(colorscheme.commentText,    0.12, colorscheme.editorBackground) },

		-- Diff preview window (hunk preview float)
		GitSignsAddPreview     = { bg = utils.shade(colorscheme.successText,    0.15, colorscheme.editorBackground) },
		GitSignsDeletePreview  = { bg = utils.shade(colorscheme.syntaxError,    0.15, colorscheme.editorBackground) },

		-- Staged signs (shown when staging individual hunks)
		GitSignsStagedAdd          = { fg = utils.mix(colorscheme.successText,    colorscheme.editorBackground, 0.65) },
		GitSignsStagedChange       = { fg = utils.mix(colorscheme.syntaxFunction, colorscheme.editorBackground, 0.65) },
		GitSignsStagedDelete       = { fg = utils.mix(colorscheme.syntaxError,    colorscheme.editorBackground, 0.65) },
		GitSignsStagedTopDelete    = { fg = utils.mix(colorscheme.syntaxError,    colorscheme.editorBackground, 0.65) },
		GitSignsStagedChangeDelete = { fg = utils.mix(colorscheme.warningEmphasis,colorscheme.editorBackground, 0.65) },

		-- Current line blame (virtual text)
		GitSignsCurrentLineBlame      = { fg = colorscheme.commentText, italic = true },
		GitSignsCurrentLineBlameNC    = { fg = colorscheme.inactiveText },
		GitSignsCurrentLineBlameFull  = { fg = colorscheme.commentText, italic = true },

		-- Word diff inside hunks
		GitSignsAddInline     = { bg = utils.shade(colorscheme.successText,    0.30, colorscheme.editorBackground) },
		GitSignsChangeInline  = { bg = utils.shade(colorscheme.syntaxFunction, 0.30, colorscheme.editorBackground) },
		GitSignsDeleteInline  = { bg = utils.shade(colorscheme.syntaxError,    0.30, colorscheme.editorBackground) },

		-- Virtual lines diff
		GitSignsVirtLnum = { fg = colorscheme.lineNumberText },
	}
end

return M

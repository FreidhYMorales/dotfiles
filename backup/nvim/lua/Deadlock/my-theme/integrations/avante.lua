local colorscheme = require("Deadlock.my-theme.colorscheme")
local utils = require("Deadlock.my-theme.utils")

local M = {}

function M.highlights()
	-- Avante uses colored bgs for titles/pills. We need a fg with enough contrast:
	-- dark mode → vivid bgs → black fg | light mode → muted bgs → white fg
	local title_fg = vim.o.background == "dark" and colorscheme.standardBlack or colorscheme.standardWhite

	return {
		-- -----------------------------------------------------------------------
		-- Sidebar headers
		-- -----------------------------------------------------------------------
		AvanteTitle = { fg = title_fg, bg = colorscheme.successText, bold = true },
		AvanteReversedTitle = { fg = colorscheme.successText },

		AvanteSubtitle = { fg = title_fg, bg = colorscheme.syntaxFunction, bold = true },
		AvanteReversedSubtitle = { fg = colorscheme.syntaxFunction },

		AvanteThirdTitle = { fg = colorscheme.inactiveText, bg = colorscheme.sidebarBackground },
		AvanteReversedThirdTitle = { fg = colorscheme.sidebarBackground },

		-- -----------------------------------------------------------------------
		-- Sidebar body
		-- -----------------------------------------------------------------------
		AvanteSidebarNormal = { link = "NormalFloat" },
		AvanteSidebarWinSeparator = {
			fg = colorscheme.windowBorder,
			bg = colorscheme.floatingWindowBackground,
		},
		AvanteSidebarWinHorizontalSeparator = {
			fg = colorscheme.windowBorder,
			bg = colorscheme.floatingWindowBackground,
		},

		-- -----------------------------------------------------------------------
		-- Diff / conflict markers
		-- -----------------------------------------------------------------------
		AvanteConflictCurrent = {
			bg = utils.shade(colorscheme.syntaxError, 0.25, colorscheme.editorBackground),
			bold = true,
		},
		AvanteConflictCurrentLabel = {
			bg = utils.shade(colorscheme.syntaxError, 0.15, colorscheme.editorBackground),
		},
		AvanteConflictIncoming = {
			bg = utils.shade(colorscheme.syntaxFunction, 0.25, colorscheme.editorBackground),
			bold = true,
		},
		AvanteConflictIncomingLabel = {
			bg = utils.shade(colorscheme.syntaxFunction, 0.15, colorscheme.editorBackground),
		},

		-- Inline suggestion / deletion marks
		AvanteToBeDeleted = {
			bg = utils.shade(colorscheme.syntaxError, 0.20, colorscheme.editorBackground),
			strikethrough = true,
		},
		AvanteToBeDeletedWOStrikethrough = {
			bg = utils.shade(colorscheme.syntaxError, 0.20, colorscheme.editorBackground),
		},

		-- -----------------------------------------------------------------------
		-- State spinner pills (bg badge shown in the sidebar while Claude works)
		-- -----------------------------------------------------------------------
		AvanteStateSpinnerGenerating  = { fg = title_fg, bg = colorscheme.specialKeyword },
		AvanteStateSpinnerThinking    = { fg = title_fg, bg = colorscheme.specialKeyword },
		AvanteStateSpinnerSearching   = { fg = title_fg, bg = colorscheme.syntaxKeyword },
		AvanteStateSpinnerToolCalling = { fg = title_fg, bg = colorscheme.syntaxFunction },
		AvanteStateSpinnerCompacting  = { fg = title_fg, bg = colorscheme.warningEmphasis },
		AvanteStateSpinnerSucceeded   = { fg = title_fg, bg = colorscheme.successText },
		AvanteStateSpinnerFailed      = { fg = title_fg, bg = colorscheme.syntaxError },

		-- -----------------------------------------------------------------------
		-- Task / thinking inline indicators (fg-only text markers)
		-- -----------------------------------------------------------------------
		AvanteTaskRunning   = { fg = colorscheme.specialKeyword },
		AvanteTaskCompleted = { fg = colorscheme.successText },
		AvanteTaskFailed    = { fg = colorscheme.errorText },
		AvanteThinking      = { fg = colorscheme.specialKeyword },

		-- -----------------------------------------------------------------------
		-- Confirm dialog title
		-- -----------------------------------------------------------------------
		AvanteConfirmTitle = { fg = title_fg, bg = colorscheme.syntaxError, bold = true },

		-- -----------------------------------------------------------------------
		-- Buttons
		-- -----------------------------------------------------------------------
		AvanteButtonDefault      = { fg = title_fg, bg = colorscheme.inactiveText },
		AvanteButtonDefaultHover = { fg = title_fg, bg = colorscheme.successText },
		AvanteButtonPrimary      = { fg = title_fg, bg = colorscheme.syntaxFunction },
		AvanteButtonPrimaryHover = { fg = title_fg, bg = colorscheme.successText },
		AvanteButtonDanger       = { fg = title_fg, bg = colorscheme.inactiveText },
		AvanteButtonDangerHover  = { fg = title_fg, bg = colorscheme.syntaxError },
	}
end

return M

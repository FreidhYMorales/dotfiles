local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

-- Color assignments per keyword type, following Night Wolf palette:
--   FIX/ERROR → syntaxError   (red)
--   TODO      → syntaxKeyword (violet)
--   HACK      → warningEmphasis (orange)
--   WARN      → warningText   (yellow)
--   PERF      → specialKeyword (light purple)
--   NOTE      → successText   (green)
--   TEST      → syntaxFunction (cyan)

function M.highlights()
	local function bg_badge(fg)
		-- Filled badge background: fg = black/white for contrast, bg = keyword color
		local badge_fg = colorscheme.is_dark and colorscheme.standardBlack or colorscheme.standardWhite
		return { fg = badge_fg, bg = fg, bold = true }
	end

	return {
		-- ── FIX / FIXME / BUG / FIXIT / ISSUE ─────────────────────────────────────
		TodoBgFIX   = bg_badge(colorscheme.syntaxError),
		TodoFgFIX   = { fg = colorscheme.syntaxError },
		TodoSignFIX = { fg = colorscheme.syntaxError },

		-- ── TODO ───────────────────────────────────────────────────────────────────
		TodoBgTODO   = bg_badge(colorscheme.syntaxKeyword),
		TodoFgTODO   = { fg = colorscheme.syntaxKeyword },
		TodoSignTODO = { fg = colorscheme.syntaxKeyword },

		-- ── HACK ───────────────────────────────────────────────────────────────────
		TodoBgHACK   = bg_badge(colorscheme.warningEmphasis),
		TodoFgHACK   = { fg = colorscheme.warningEmphasis },
		TodoSignHACK = { fg = colorscheme.warningEmphasis },

		-- ── WARN / WARNING / XXX ───────────────────────────────────────────────────
		TodoBgWARN   = bg_badge(colorscheme.warningText),
		TodoFgWARN   = { fg = colorscheme.warningText },
		TodoSignWARN = { fg = colorscheme.warningText },

		-- ── PERF / OPTIM / PERFORMANCE ─────────────────────────────────────────────
		TodoBgPERF   = bg_badge(colorscheme.specialKeyword),
		TodoFgPERF   = { fg = colorscheme.specialKeyword },
		TodoSignPERF = { fg = colorscheme.specialKeyword },

		-- ── NOTE / INFO ────────────────────────────────────────────────────────────
		TodoBgNOTE   = bg_badge(colorscheme.successText),
		TodoFgNOTE   = { fg = colorscheme.successText },
		TodoSignNOTE = { fg = colorscheme.successText },

		-- ── TEST / TESTING / PASSED / FAILED ──────────────────────────────────────
		TodoBgTEST   = bg_badge(colorscheme.syntaxFunction),
		TodoFgTEST   = { fg = colorscheme.syntaxFunction },
		TodoSignTEST = { fg = colorscheme.syntaxFunction },
	}
end

return M

local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	local bg = colorscheme.floatingWindowBackground
	return {
		-- Popup window
		WhichKeyNormal  = { fg = colorscheme.mainText,    bg = bg },
		WhichKeyBorder  = { fg = colorscheme.emphasisText, bg = bg },
		WhichKeyTitle   = { fg = colorscheme.emphasisText, bg = bg, bold = true },
		WhichKeyFooter  = { fg = colorscheme.inactiveText, bg = bg },

		-- Mapping columns
		WhichKey        = { fg = colorscheme.syntaxFunction, bold = true },  -- the key itself
		WhichKeyDesc    = { fg = colorscheme.mainText },                      -- description
		WhichKeySeparator = { fg = colorscheme.commentText },                 -- the → between key and desc
		WhichKeyGroup   = { fg = colorscheme.syntaxKeyword, bold = true },    -- group label (e.g. "+git")
		WhichKeyValue   = { fg = colorscheme.warningText },                   -- RHS value

		-- Icons
		WhichKeyIconAzure  = { fg = colorscheme.linkText },
		WhichKeyIconBlue   = { fg = colorscheme.linkText },
		WhichKeyIconCyan   = { fg = colorscheme.syntaxFunction },
		WhichKeyIconGreen  = { fg = colorscheme.successText },
		WhichKeyIconGrey   = { fg = colorscheme.inactiveText },
		WhichKeyIconOrange = { fg = colorscheme.warningEmphasis },
		WhichKeyIconPurple = { fg = colorscheme.specialKeyword },
		WhichKeyIconRed    = { fg = colorscheme.syntaxError },
		WhichKeyIconYellow = { fg = colorscheme.warningText },
	}
end

return M

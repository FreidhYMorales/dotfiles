local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	return {
		NoiceCmdlinePopupBorder = { fg = colorscheme.emphasisText }, -- white border for cmdline
		NoiceCmdlinePopupBorderCalculator = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderCmdline = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderFilter = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderHelp = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderIncRename = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderInput = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderLua = { fg = colorscheme.emphasisText },
		NoiceCmdlinePopupBorderSearch = { fg = colorscheme.emphasisText },
		NoiceConfirmBorder = { fg = colorscheme.emphasisText },
		NoicePopupBorder = { fg = colorscheme.emphasisText },
		NoicePopupmenuBorder = { fg = colorscheme.emphasisText },
		NoiceSplitBorder = { fg = colorscheme.emphasisText },
	}
end

return M

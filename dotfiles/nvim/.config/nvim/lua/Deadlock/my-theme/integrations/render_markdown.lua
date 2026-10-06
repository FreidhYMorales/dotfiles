local colorscheme = require("Deadlock.my-theme.colorscheme")
local utils = require("Deadlock.my-theme.utils")

local M = {}

-- Monochrome heading ramp (brightest → dimmest) derived from the active
-- palette, so it stays readable on light and terminal variants too.
function M.highlights()
	local bg = colorscheme.editorBackground
	local fg = colorscheme.emphasisText

	return {
		RenderMarkdownH1         = { fg = fg, bold = true },
		RenderMarkdownH2         = { fg = utils.mix(fg, bg, 0.88), bold = true },
		RenderMarkdownH3         = { fg = utils.mix(fg, bg, 0.75), bold = true },
		RenderMarkdownH4         = { fg = utils.mix(fg, bg, 0.62), bold = true },
		RenderMarkdownListBullet = { fg = utils.mix(colorscheme.mainText, bg, 0.65) },
		RenderMarkdownQuote      = { fg = colorscheme.commentText, italic = true },
		RenderMarkdownCode       = { fg = colorscheme.mainText, bg = colorscheme.popupBackground },
		RenderMarkdownTable      = { fg = utils.mix(colorscheme.mainText, bg, 0.75) },
		RenderMarkdownMath       = { fg = colorscheme.syntaxLightBlue, italic = true },
	}
end

return M

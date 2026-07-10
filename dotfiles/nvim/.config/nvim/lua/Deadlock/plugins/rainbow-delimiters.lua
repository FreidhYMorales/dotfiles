return {
	"HiPhish/rainbow-delimiters.nvim",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local rainbow = require("rainbow-delimiters")
		vim.g.rainbow_delimiters = {
			strategy = {
				[""] = rainbow.strategy["global"],
			},
			query = {
				-- Use only bracket-level queries — NOT rainbow-blocks (that colors
				-- Lua keywords like function/end/do as block delimiters, which is wrong)
				[""] = "rainbow-delimiters",
			},
			priority = {
				[""] = 110,
			},
			-- Matches NightWolf editorBracketHighlight.foreground1-6 cycle
			highlight = {
				"RainbowDelimiterYellow",  -- 1  syntaxYellow  #FFDC96
				"RainbowDelimiterRed",     -- 2  syntaxRed     #FF7878
				"RainbowDelimiterBlue",    -- 3  syntaxBlue    #00B1FF
				"RainbowDelimiterOrange",  -- 4  syntaxOrange  #FFB482
				"RainbowDelimiterViolet",  -- 5  syntaxPurple  #DC8CFF
				"RainbowDelimiterGreen",   -- 6  syntaxGreen   #AAE682
			},
		}
	end,
}

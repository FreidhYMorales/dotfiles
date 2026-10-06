-- blink.nvim — only the chartoggle module is used (pure Lua, no cargo build:
-- that is only needed by the unused delimiters module). The tree module was
-- dropped in favor of oil + yazi.nvim.
return {
	"saghen/blink.nvim",
	keys = {
		{
			"<C-;>",
			function()
				require("blink.chartoggle").toggle_char_eol(";")
			end,
			mode = { "n", "v" },
			desc = "Toggle ; at eol",
		},
		{
			"<M-,>",
			function()
				require("blink.chartoggle").toggle_char_eol(",")
			end,
			mode = { "n", "v" },
			desc = "Toggle , at eol",
		},
	},
	-- Loaded on its keys (chartoggle only needs setup before the first press)
	opts = {
		chartoggle = { enabled = true },
	},
}

return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		max_lines = 3,
		min_window_height = 20,
		multiline_threshold = 1,
	},
	keys = {
		{
			"<leader>ut",
			function()
				require("treesitter-context").toggle()
			end,
			desc = "Toggle treesitter context",
		},
	},
}

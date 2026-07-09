return {
	"saghen/blink.nvim",
	build = "cargo build --release", -- for delimiters
	keys = {
		-- chartoggle
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

		-- tree
		{ "<leader>er", "<cmd>BlinkTree reveal<cr>", desc = "Reveal in tree" },
		{ "<leader>eT", "<cmd>BlinkTree toggle<cr>", desc = "Toggle tree" },
		{ "<leader>et", "<cmd>BlinkTree toggle-focus<cr>", desc = "Toggle tree focus" },
	},
	-- all modules handle lazy loading internally
	lazy = false,
	opts = {
		chartoggle = { enabled = true },
		tree = { enabled = true },
	},
}

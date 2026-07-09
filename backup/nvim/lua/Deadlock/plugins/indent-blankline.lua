return {
	"lukas-reineke/indent-blankline.nvim",
	event = { "BufReadPost", "BufNewFile" },
	main = "ibl",
	dependencies = { "HiPhish/rainbow-delimiters.nvim" },
	opts = {
		indent = {
			char = "│",
			tab_char = "│",
		},
		scope = {
			show_start = true,
			show_end = false,
			highlight = {
				"RainbowDelimiterYellow",
				"RainbowDelimiterRed",
				"RainbowDelimiterBlue",
				"RainbowDelimiterOrange",
				"RainbowDelimiterViolet",
				"RainbowDelimiterGreen",
			},
		},
		exclude = {
			filetypes = {
				"help",
				"alpha",
				"dashboard",
				"neo-tree",
				"Trouble",
				"trouble",
				"lazy",
				"mason",
				"notify",
				"toggleterm",
				"lazyterm",
			},
		},
	},
}

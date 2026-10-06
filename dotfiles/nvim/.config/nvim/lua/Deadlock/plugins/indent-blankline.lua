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
			-- Same order as rainbow-delimiters.lua's highlight list
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
			-- help, nofile buffers (dashboard, pickers) are excluded by default
			filetypes = { "Trouble", "trouble", "lazy", "mason" },
		},
	},
	config = function(_, opts)
		require("ibl").setup(opts)
		-- Scope guide takes the color of the delimiter at that scope (ibl docs:
		-- rainbow-delimiters integration) instead of cycling by scope index
		local hooks = require("ibl.hooks")
		hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
	end,
}

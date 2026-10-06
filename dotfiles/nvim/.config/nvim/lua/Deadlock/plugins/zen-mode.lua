return {
	"folke/zen-mode.nvim",
	cmd = "ZenMode",
	opts = {
		plugins = {
			-- laststatus=3 keeps the global lualine visible in zen; hide it
			-- (zen-mode restores the value on close)
			options = { enabled = true, laststatus = 0 },
			gitsigns = true,
			kitty = { enabled = false, font = "+2" },
			twilight = { enabled = true },
		},
	},
	keys = {
		{ "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle ZenMode" },
	},
}

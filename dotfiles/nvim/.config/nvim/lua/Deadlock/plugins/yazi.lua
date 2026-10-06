-- Yazi (with the user's own yazi config/plugins) in a floating window.
-- Oil stays the editor for the filesystem and keeps ownership of directory
-- buffers, so open_for_directories is off.
return {
	"mikavilpas/yazi.nvim",
	version = "*",
	dependencies = {
		{ "nvim-lua/plenary.nvim", lazy = true },
	},
	keys = {
		{ "<leader>ey", "<cmd>Yazi<cr>", mode = { "n", "v" }, desc = "Yazi (current file)" },
		{ "<leader>eY", "<cmd>Yazi cwd<cr>", desc = "Yazi (cwd)" },
		{ "<leader>er", "<cmd>Yazi toggle<cr>", desc = "Yazi (resume last session)" },
	},
	---@type YaziConfig | {}
	opts = {
		open_for_directories = false,
		keymaps = {
			show_help = "<f1>",
		},
	},
}

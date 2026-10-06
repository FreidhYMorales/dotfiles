return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		default_file_explorer = true,
		skip_confirm_for_simple_edits = true,
		delete_to_trash = true,
		view_options = {
			show_hidden = false,
			case_insensitive = true,
			sort = {
				{ "type", "asc" },
				{ "name", "asc" },
			},
		},
		keymaps = {
			["q"] = { "actions.close", mode = "n" },
			-- Free global mappings that oil's defaults shadow: <C-s> save and
			-- <C-h>/<C-l> window navigation (keymaps.lua). Splits move to
			-- <C-v>/<C-x> and refresh to gR.
			["<C-s>"] = false,
			["<C-h>"] = false,
			["<C-l>"] = false,
			["<C-v>"] = { "actions.select", opts = { vertical = true } },
			["<C-x>"] = { "actions.select", opts = { horizontal = true } },
			["gR"] = "actions.refresh",
			-- Hidden files toggle stays on its default g. — "." is dot-repeat,
			-- needed when editing the directory buffer by hand.
		},
	},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- Lazy loading is not recommended: oil must own directory buffers at startup
	lazy = false,
}

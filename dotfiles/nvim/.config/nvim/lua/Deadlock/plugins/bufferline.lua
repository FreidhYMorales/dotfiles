return {
	"akinsho/bufferline.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = "nvim-tree/nvim-web-devicons",
	opts = {
		-- my-theme's bufferline integration (integrations/bufferline.lua).
		-- A function, so bufferline re-reads it on every ColorScheme and picks
		-- up the active Night Wolf variant; other colorschemes get defaults.
		highlights = function()
			if vim.g.colors_name == "my-theme" then
				return require("Deadlock.my-theme.init").bufferline.highlights
			end
			return {}
		end,
		options = {
			close_command = function(n)
				require("snacks").bufdelete(n)
			end,
			right_mouse_command = function(n)
				require("snacks").bufdelete(n)
			end,
			diagnostics = "nvim_lsp",
			always_show_bufferline = false,
			diagnostics_indicator = function(_, _, diag)
				local icons = {
					Error = " ",
					Warn = " ",
					Hint = " ",
					Info = " ",
				}
				local ret = (diag.error and icons.Error .. diag.error .. " " or "")
					.. (diag.warning and icons.Warn .. diag.warning or "")
				return vim.trim(ret)
			end,
			offsets = {
				{
					filetype = "snacks_layout_box",
				},
			},
		},
	},
}

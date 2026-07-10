return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local colors = require("Deadlock.my-theme.colorscheme")

		local theme = {
			normal = {
				a = { fg = colors.editorBackground, bg = colors.syntaxFunction, gui = "bold" },
				b = { fg = colors.mainText, bg = colors.popupBackground },
				c = { fg = colors.inactiveText, bg = "NONE" },
			},
			insert = {
				a = { fg = colors.editorBackground, bg = colors.stringText, gui = "bold" },
			},
			visual = {
				a = { fg = colors.editorBackground, bg = colors.specialKeyword, gui = "bold" },
			},
			replace = {
				a = { fg = colors.editorBackground, bg = colors.syntaxError, gui = "bold" },
			},
			command = {
				a = { fg = colors.editorBackground, bg = colors.warningText, gui = "bold" },
			},
			inactive = {
				a = { fg = colors.inactiveText, bg = "NONE" },
				b = { fg = colors.inactiveText, bg = "NONE" },
				c = { fg = colors.inactiveText, bg = "NONE" },
			},
		}

		require("lualine").setup({
			options = {
				theme = theme,
				globalstatus = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = { "snacks_dashboard" },
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" },
				lualine_c = {
					{ "filename", path = 1, symbols = { modified = " ", readonly = " " } },
				},
				lualine_x = {
					{
						"diagnostics",
						symbols = { error = " ", warn = " ", hint = "󰠠 ", info = " " },
					},
					"filetype",
				},
				lualine_y = { "encoding", "fileformat" },
				lualine_z = { "location", "progress" },
			},
		})
	end,
}

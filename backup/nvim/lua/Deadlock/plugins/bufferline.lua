return {
	"akinsho/bufferline.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = "nvim-tree/nvim-web-devicons",
	opts = {
		options = {
          -- stylua: ignore
          close_command = function(n)
			  require("snacks").bufdelete(n)
		  end,
          -- stylua: ignore
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
	config = function(_, opts)
		require("bufferline").setup(opts)
	end,
}

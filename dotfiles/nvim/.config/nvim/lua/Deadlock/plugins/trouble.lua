return {
	"folke/trouble.nvim",
	-- todo-comments has its own spec; it is only needed by <leader>xt
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		focus = true,
	},
	cmd = "Trouble",
	keys = {
		{ "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Toggle Trouble" },
		{ "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics" },
		{ "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Document diagnostics" },
		{ "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbols (Trouble)" },
		{ "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", desc = "Quickfix list" },
		{ "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
		{ "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Todos" },
		-- v3 skips group rows on its own (skip_groups was a v2 option)
		{
			"[q",
			function()
				if require("trouble").is_open() then
					require("trouble").prev({ jump = true })
				else
					local ok, err = pcall(vim.cmd.cprev)
					if not ok then
						vim.notify(err, vim.log.levels.ERROR)
					end
				end
			end,
			desc = "Previous Trouble/Quickfix item",
		},
		{
			"]q",
			function()
				if require("trouble").is_open() then
					require("trouble").next({ jump = true })
				else
					local ok, err = pcall(vim.cmd.cnext)
					if not ok then
						vim.notify(err, vim.log.levels.ERROR)
					end
				end
			end,
			desc = "Next Trouble/Quickfix item",
		},
	},
}

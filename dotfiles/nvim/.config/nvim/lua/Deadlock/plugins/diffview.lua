return {
	-- Actively maintained drop-in fork of sindrets/diffview.nvim (unmaintained
	-- since 2024-06): same module and commands
	"dlyongemallo/diffview-plus.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	keys = {
		{
			"<leader>gd",
			function()
				if next(require("diffview.lib").views) then
					vim.cmd("DiffviewClose")
				else
					vim.cmd("DiffviewOpen")
				end
			end,
			desc = "Git diff view (toggle)",
		},
		{ "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current)" },
		{ "<leader>gF", "<cmd>DiffviewFileHistory<CR>", desc = "File history (repo)" },
	},
	opts = {
		view = {
			merge_tool = {
				layout = "diff3_mixed",
			},
		},
	},
}

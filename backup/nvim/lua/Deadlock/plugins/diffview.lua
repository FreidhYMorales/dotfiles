return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Git diff view" },
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

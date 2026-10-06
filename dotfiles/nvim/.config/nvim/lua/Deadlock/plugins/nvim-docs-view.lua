return {
	"amrbashir/nvim-docs-view",
	cmd = "DocsViewToggle",
	keys = {
		{ "<leader>uD", "<cmd>DocsViewToggle<cr>", desc = "Docs view (LSP hover panel)" },
	},
	opts = {
		position = "right",
		width = 60,
	},
}

return {
	"MeanderingProgrammer/render-markdown.nvim",
	-- Runs on the filetypes in `ft` (no need to repeat them in file_types)
	ft = { "markdown" },
	-- Icons from nvim-web-devicons, the provider the rest of the config uses
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	opts = {
		heading = {
			enabled = true,
			sign = true,
			style = "full",
			icons = { "① ", "② ", "③ ", "④ ", "⑤ ", "⑥ " },
			left_pad = 1,
		},
		bullet = {
			enabled = true,
			icons = { "●", "○", "◆", "◇" },
			right_pad = 1,
			highlight = "RenderMarkdownListBullet",
		},
		-- Only when a converter is installed (pacman -S python-pylatexenc);
		-- otherwise it fails silently and :checkhealth warns
		latex = {
			enabled = vim.fn.executable("latex2text") == 1,
			converter = { "latex2text", "utftex" },
			highlight = "RenderMarkdownMath",
		},
		-- Checkbox/callout completions through the in-process LSP (works with blink)
		completions = { lsp = { enabled = true } },
	},
	-- Highlight groups come from my-theme (integrations/render_markdown.lua)
}

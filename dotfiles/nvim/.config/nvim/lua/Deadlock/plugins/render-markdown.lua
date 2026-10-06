return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter", { "echasnovski/mini.icons", opts = {} } },
	opts = {
		file_types = { "markdown" },
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
		latex = {
			enabled = true,
			converter = { "latex2text", "utftex" },
			highlight = "RenderMarkdownMath",
		},
	},
	-- Highlight groups come from my-theme (integrations/render_markdown.lua)
}

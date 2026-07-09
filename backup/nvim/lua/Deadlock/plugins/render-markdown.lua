return {
	"MeanderingProgrammer/render-markdown.nvim",
	-- "Avante" incluido: el panel de avante usa ese filetype para las respuestas de Claude
	ft = { "markdown", "Avante", "codecompanion" },
	dependencies = { "nvim-treesitter/nvim-treesitter", { "echasnovski/mini.icons", opts = {} } },
	opts = {
		file_types = { "markdown", "Avante", "codecompanion" },
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
	config = function(_, opts)
		require("render-markdown").setup(opts)

		-- 🎨 Ajuste de colores neutros para fondo oscuro
		vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#FFFFFF", bold = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#E0E0E0", bold = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#BFBFBF", bold = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#9E9E9E", bold = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownListBullet", { fg = "#AAAAAA" })
		vim.api.nvim_set_hl(0, "RenderMarkdownQuote", { fg = "#888888", italic = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownCode", { fg = "#CCCCCC", bg = "#1E1E1E" })
		vim.api.nvim_set_hl(0, "RenderMarkdownTable", { fg = "#BBBBBB" })
		vim.api.nvim_set_hl(0, "RenderMarkdownMath", { fg = "#C8D0E0", italic = true })
	end,
}

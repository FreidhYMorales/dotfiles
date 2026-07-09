return {
	"NickvanDyke/opencode.nvim",
	dependencies = { "folke/snacks.nvim" },
	keys = {
		{
			"<leader>ao",
			function()
				require("opencode").toggle()
			end,
			mode = { "n" },
			desc = "Toggle",
		},
		{
			"<leader>aos",
			function()
				require("opencode").select({ submit = true })
			end,
			mode = { "n", "x" },
			desc = "Select",
		},
		{
			"<leader>aoi",
			function()
				require("opencode").ask("", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Ask",
		},
		{
			"<leader>aoI",
			function()
				require("opencode").ask("@this: ", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Ask with context",
		},
		{
			"<leader>aob",
			function()
				require("opencode").ask("@file ", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Ask about buffer",
		},
		{
			"<leader>aop",
			function()
				require("opencode").prompt("@this", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Prompt",
		},
		-- Built-in prompts
		{
			"<leader>aope",
			function()
				require("opencode").prompt("explain", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Explain",
		},
		{
			"<leader>aopf",
			function()
				require("opencode").prompt("fix", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Fix",
		},
		{
			"<leader>aopd",
			function()
				require("opencode").prompt("diagnose", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Diagnose",
		},
		{
			"<leader>aopr",
			function()
				require("opencode").prompt("review", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Review",
		},
		{
			"<leader>aopt",
			function()
				require("opencode").prompt("test", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Test",
		},
		{
			"<leader>aopo",
			function()
				require("opencode").prompt("optimize", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Optimize",
		},
	},
	config = function()
		-- autoread=true: necesario para que los cambios que opencode escribe en disco
		-- se reflejen automáticamente en Neovim sin recargar manualmente.
		-- Efecto global intencional: cualquier archivo modificado externamente se recarga.
		vim.o.autoread = true
	end,
}

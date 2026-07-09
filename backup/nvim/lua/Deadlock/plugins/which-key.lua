return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts_extend = { "spec" },
	opts = {
		preset = "helix",
		defaults = {},
		spec = {
			{
				mode = { "n", "x" },

				-- AI tools
				{ "<leader>a",   group = "ai" },
				{ "<leader>aa",  group = "avante" },
				{ "<leader>ac",  group = "claude code" },
				{ "<leader>ag",  group = "gemini" },
				{ "<leader>an",  group = "codecompanion" },
				{ "<leader>ao",  group = "opencode" },
				{ "<leader>aop", group = "prompts" },

				-- Core groups
				{ "<leader><tab>", group = "tabs" },
				{ "<leader>b",     group = "buffer" },
				{ "<leader>c",     group = "code" },     -- format, actions, diagnostics, lint
				{ "<leader>d",     group = "debug" },
				{ "<leader>e",     group = "explorer" },
				{ "<leader>f",     group = "file" },     -- fn, fp, fx

				-- Git
				{ "<leader>g",     group = "git" },
				{ "<leader>gb",    group = "branches" },
				{ "<leader>gh",    group = "hunks" },
				{ "<leader>gt",    group = "toggle" },

				-- LSP (global) — buffer-local via LspAttach en lspconfig.lua
				{ "<leader>l",     group = "lsp" },      -- lr restart, li hints, ll log, lm mason

				-- Picker / search / navigation
				{ "<leader>h",     group = "harpoon" },
				{ "<leader>p",     group = "picker" },
				{ "<leader>s",     group = "search/replace" },
				{ "<leader>v",     group = "view/help" },

				-- Session / quit
				{ "<leader>q",     group = "quit/session" },

				-- Rename (buffer-local LSP, declarado aquí para el grupo)
				{ "<leader>r",     group = "rename/restart" },

				-- UI toggles
				{ "<leader>u",     group = "ui/toggle" },

				-- Window management (proxy <C-w> para hydra mode)
				{
					"<leader>w",
					group = "window",
					proxy = "<c-w>",
					expand = function()
						return require("which-key.extras").expand.win()
					end,
				},

				-- Diagnostics / quickfix (Trouble)
				{ "<leader>x", group = "diagnostics/quickfix" },

				-- Navigation prev/next
				{ "[", group = "prev" },
				{ "]", group = "next" },

				-- Standard Vim prefixes
				{ "g",  group = "goto" },
				{ "gs", group = "surround" },
				{ "z",  group = "fold" },

				-- Descriptions puntuales
				{ "gx", desc = "Open with system app" },
				{ "\\", desc = "Explorer (Oil)" },
			},
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
		{
			"<c-w><space>",
			function()
				require("which-key").show({ keys = "<c-w>", loop = true })
			end,
			desc = "Window Hydra Mode (which-key)",
		},
	},
}

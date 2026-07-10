return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
	},
	cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
	keys = {
		{ "<leader>an", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle chat", mode = { "n", "v" } },
		{ "<leader>ana", "<cmd>CodeCompanionActions<cr>", desc = "Actions", mode = { "n", "v" } },
		{ "<leader>anc", "<cmd>CodeCompanionChat<cr>", desc = "New chat" },
		{ "<leader>ans", "<cmd>CodeCompanionChat Add<cr>", desc = "Send to chat", mode = "v" },
		{ "<leader>ani", "<cmd>CodeCompanion<cr>", desc = "Inline assistant", mode = { "n", "v" } },
		{ "<leader>anm", "<cmd>CodeCompanionCmd<cr>", desc = "Generate command" },
	},
	opts = {
		system_prompt = function(_)
			return [[
Asistente técnico para Estudiante de Ingeniería en Ciencias de la Computación.

STACK: Neovim/Lua, TypeScript, Go, Python, C/C++ — Arch Linux/Hyprland/Wayland.

REGLAS:
- Respuestas directas y técnicas. Sin introducción innecesaria.
- Código idiomático del lenguaje actual. Seguir convenciones del archivo (tabs, naming).
- Errores: diagnóstico + causa raíz, luego fix — no el fix aislado.
- Trade-offs en una línea cuando hay múltiples enfoques.
- No agregar docstrings/comentarios en código que no los necesita.
			]]
		end,
		interactions = {
			chat = { adapter = "gemini" },
			inline = { adapter = "gemini" },
		},
		adapters = {
			http = {
				gemini = function()
					return require("codecompanion.adapters").extend("gemini", {
						schema = {
							model = {
								default = "gemini-2.5-flash",
							},
							thinkingLevel = {
								enabled = function() return false end,
							},
						},
					})
				end,
			},
		},
		display = {
			action_palette = {
				provider = "snacks",
			},
			chat = {
				window = {
					layout = "vertical",
					width = 0.35,
					border = "rounded",
				},
				slash_commands = {
					opts = { provider = "snacks" },
				},
				separator = "─",
				show_header_separator = false, -- render-markdown handles headers
				show_settings = true,          -- muestra modelo activo en la parte superior
				show_token_count = true,
				show_context = true,
				fold_context = true,           -- colapsa el contexto añadido para reducir ruido
				start_in_insert_mode = true,
				token_count = function(tokens, adapter)
					return "  " .. adapter.formatted_name .. " · " .. tokens .. " tokens"
				end,
			},
		},
		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					make_vars = true,
					make_slash_commands = true,
					show_result_in_chat = true,
				},
			},
		},
	},
	config = function(_, opts)
		require("codecompanion").setup(opts)

		-- Auto-format buffer after inline assistant finishes
		vim.api.nvim_create_autocmd("User", {
			pattern = "CodeCompanionInlineFinished",
			callback = function(event)
				require("conform").format({ bufnr = event.buf })
			end,
		})
	end,
}

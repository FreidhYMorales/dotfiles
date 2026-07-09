return {
	"yetone/avante.nvim",
	-- event omitido: los keys = {} ya disparan la carga (antes era VeryLazy → cargaba siempre)
	version = false,
	build = "make",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		provider = "claude",
		system_prompt = function()
			return [[
Eres un asistente técnico experto para un Estudiante de Ingeniería en Ciencias de la Computación.

CONTEXTO DEL ENTORNO:
- Editor: Neovim 0.11+ con Lua, lazy.nvim, blink.cmp, treesitter
- OS: Arch Linux con Hyprland (Wayland)
- Lenguajes principales: Lua, TypeScript, Go, Python, C/C++

COMPORTAMIENTO:
- Respuestas concisas y técnicas — sin relleno pedagógico innecesario
- Priorizar soluciones idiomáticas del lenguaje (Go idioms, Lua nativo, TS types)
- Cuando propongas código, seguir las convenciones del archivo actual (tabs/spaces, naming)
- Si hay varios enfoques, presenta el trade-off en una línea, luego la recomendación
- Para errores: diagnóstico primero, fix después — no el fix solo
- Documentación solo si la lógica no es autoevidente
			]]
		end,
		providers = {
			claude = {
				endpoint = "https://api.anthropic.com",
				model = "claude-sonnet-4-20250514",
				extra_request_body = {
					max_tokens = 8096,
				},
			},
		},
		behaviour = {
			auto_suggestions = false,
			auto_set_keymaps = true,
			auto_set_highlight_group = true,
			support_paste_from_clipboard = true,
		},
		windows = {
			position = "right",
			width = 40,
			sidebar_header = {
				align = "center",
			},
		},
		input = {
			provider = "snacks",
		},
		selector = {
			provider = "snacks",
		},
	},
	keys = {
		{ "<leader>aa", function() require("avante.api").ask() end, desc = "Ask", mode = { "n", "v" } },
		{ "<leader>aae", function() require("avante.api").edit() end, desc = "Edit", mode = "v" },
		{ "<leader>aar", function() require("avante.api").refresh() end, desc = "Refresh" },
		{ "<leader>aat", "<cmd>AvanteToggle<CR>", desc = "Toggle" },
	},
}

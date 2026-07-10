return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					-- auto_trigger=false: evita conflicto visual con blink.cmp ghost_text.
					-- Ambos usan virt_text en la misma posición del cursor — solo uno gana.
					-- Copilot se activa manualmente: <M-]> siguiente sugerencia, <M-l> aceptar.
					auto_trigger = false,
					keymap = {
						accept = false,
						accept_word = false,
						accept_line = false,
						next = false,
						prev = false,
						dismiss = false,
					},
				},
				panel = { enabled = false },
				filetypes = {
					markdown = true,
					help = false,
					["."] = false,
				},
			})
		end,
		keys = {
			{ "<M-l>", function() require("copilot.suggestion").accept() end, desc = "Copilot: Accept", mode = "i" },
			{ "<M-j>", function() require("copilot.suggestion").accept_line() end, desc = "Copilot: Accept Line", mode = "i" },
			{ "<M-k>", function() require("copilot.suggestion").accept_word() end, desc = "Copilot: Accept Word", mode = "i" },
			{ "<M-]>", function() require("copilot.suggestion").next() end, desc = "Copilot: Next / Trigger", mode = "i" },
			{ "<M-[>", function() require("copilot.suggestion").prev() end, desc = "Copilot: Prev", mode = "i" },
			{ "<C-]>", function() require("copilot.suggestion").dismiss() end, desc = "Copilot: Dismiss", mode = "i" },
		},
	},
}

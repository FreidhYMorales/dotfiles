return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		lint.linters_by_ft = {
			-- JavaScript/TypeScript
			javascript = {"biomejs"},
			typescript = {"biomejs"},
			javascriptreact = {"biomejs"},
			typescriptreact = {"biomejs"},
			svelte = { "biomejs" },

			-- Python
			python = { "pylint" },

			-- Shell scripts
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			zsh = { "shellcheck" },

			-- C/C++
			c = { "cpplint" },
			cpp = { "cpplint" },
		}

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>cl", function()
			lint.try_lint()
		end, { desc = "Lint current file" })
	end,
}

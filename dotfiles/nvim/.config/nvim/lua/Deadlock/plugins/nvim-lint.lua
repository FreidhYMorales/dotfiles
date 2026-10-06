return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>cl",
			function()
				require("lint").try_lint()
			end,
			desc = "Lint current file",
		},
	},
	config = function()
		local lint = require("lint")
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		lint.linters_by_ft = {
			-- JS/TS: biome language server (lspconfig.lua) — live diagnostics on
			-- the buffer; nvim-lint's biomejs had stdin=false and linted the
			-- on-disk file, so unsaved edits got stale results.

			-- Python: linted by the ruff language server (lspconfig.lua)

			-- Shell scripts
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			-- zsh: shellcheck does not support it (SC1071)

			-- C/C++: no linter here, clangd already runs clang-tidy
		}

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}

-- nvim-treesitter `main` branch: no lazy-loading, no ensure_installed/highlight
-- options. Parsers are installed via install() and highlighting is started
-- per buffer with vim.treesitter.start(). Requires the `tree-sitter` CLI.
local parsers = {
	-- Languages you use
	"lua",
	"javascript",
	"typescript",
	"tsx",
	"html",
	"css",
	"scss",
	"json",
	"yaml",
	"graphql",
	"svelte",
	"go",
	"gomod",
	"gosum",
	"python",
	"c",
	"cpp",
	"c_sharp",
	"rust",
	"bash",
	"zsh",
	"toml", -- yazi, matugen, starship configs
	"hyprlang", -- Hyprland .conf files
	"kitty",
	"markdown",
	"markdown_inline",
	"latex",
	-- Utility
	"vim",
	"vimdoc",
	"regex",
	"query",
	"diff",
	"gitcommit",
	"git_rebase",
	"qmljs", -- QML (Quickshell)
	"qmldir", -- Quickshell module qmldir files
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		if vim.fn.executable("tree-sitter") == 1 then
			ts.install(parsers)
		else
			vim.notify(
				"tree-sitter CLI not found: parsers cannot be installed (pacman -S tree-sitter-cli)",
				vim.log.levels.WARN,
				{ title = "treesitter" }
			)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(ev)
				local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
				if not lang or not vim.treesitter.language.add(lang) then
					return
				end
				vim.treesitter.start(ev.buf, lang)
			end,
		})
	end,
}

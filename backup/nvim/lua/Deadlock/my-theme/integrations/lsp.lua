local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	return {
		-- LSP floating windows (hover, signature help, etc.)
		-- These use NormalFloat and FloatBorder by default, but we can customize them
		LspInfoBorder = { fg = colorscheme.emphasisText, bg = "NONE" },  -- white border, transparent bg

		-- LSP signature help
		LspSignatureActiveParameter = { fg = colorscheme.warningText, bold = true },  -- highlight active parameter

		-- LSP references
		LspReferenceText = { bg = colorscheme.menuOptionBackground },
		LspReferenceRead = { bg = colorscheme.menuOptionBackground },
		LspReferenceWrite = { bg = colorscheme.menuOptionBackground, underline = true },

		-- LSP code lens
		LspCodeLens = { fg = colorscheme.commentText, italic = true },
		LspCodeLensSeparator = { fg = colorscheme.commentText },

		-- LSP inlay hints
		LspInlayHint = { fg = colorscheme.commentText, italic = true },
	}
end

return M

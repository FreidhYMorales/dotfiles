local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	return {
		-- Popup menu (completion window) - base Neovim groups
		Pmenu = { bg = "NONE", fg = colorscheme.mainText },  -- transparent background
		PmenuSel = { bg = colorscheme.menuOptionBackground, fg = colorscheme.emphasisText },
		PmenuSbar = { bg = colorscheme.windowBorder },  -- scrollbar background
		PmenuThumb = { bg = colorscheme.emphasisText },  -- scrollbar thumb
		PmenuMatch = { bg = "NONE", fg = colorscheme.linkText, bold = true },  -- matched text
		PmenuMatchSel = { bg = colorscheme.menuOptionBackground, fg = colorscheme.linkText, bold = true },  -- matched text selected

		-- Cmp documentation window
		CmpDocumentation = { link = "NormalFloat" },
		CmpDocumentationBorder = { fg = colorscheme.emphasisText, bg = colorscheme.floatingWindowBackground },

		-- Cmp completion border (explicit definition)
		CmpBorder = { fg = colorscheme.emphasisText, bg = "NONE" },

		-- Cmp specific highlights
		CmpItemAbbr = { fg = colorscheme.mainText },
		CmpItemAbbrDeprecated = { fg = colorscheme.mainText, strikethrough = true },
		CmpItemKind = { fg = colorscheme.syntaxFunction },
		CmpItemMenu = { fg = colorscheme.commentText },  -- more subtle
		CmpItemAbbrMatch = { fg = colorscheme.linkText, bold = true },  -- blue for matches
		CmpItemAbbrMatchFuzzy = { fg = colorscheme.linkText, bold = true },

		-- kind support (Night Wolf colors)
		CmpItemKindSnippet = { fg = colorscheme.stringText },  -- green
		CmpItemKindKeyword = { fg = colorscheme.syntaxKeyword },  -- darkPurple
		CmpItemKindText = { fg = colorscheme.mainText },  -- muted
		CmpItemKindMethod = { fg = colorscheme.syntaxFunction },  -- cyan
		CmpItemKindConstructor = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindFunction = { fg = colorscheme.syntaxFunction },  -- cyan
		CmpItemKindFolder = { fg = colorscheme.linkText },  -- blue
		CmpItemKindModule = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindConstant = { fg = colorscheme.lightRed },  -- lightRed
		CmpItemKindField = { fg = colorscheme.property },  -- lightYellow
		CmpItemKindProperty = { fg = colorscheme.property },  -- lightYellow
		CmpItemKindEnum = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindUnit = { fg = colorscheme.warningText },  -- lightYellow
		CmpItemKindClass = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindVariable = { fg = colorscheme.mainText },  -- muted
		CmpItemKindFile = { fg = colorscheme.linkText },  -- blue
		CmpItemKindInterface = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindColor = { fg = colorscheme.warningText },  -- lightYellow
		CmpItemKindReference = { fg = colorscheme.linkText },  -- blue
		CmpItemKindEnumMember = { fg = colorscheme.lightRed },  -- lightRed
		CmpItemKindStruct = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindValue = { fg = colorscheme.lightRed },  -- lightRed
		CmpItemKindEvent = { fg = colorscheme.warningText },  -- lightYellow
		CmpItemKindOperator = { fg = colorscheme.syntaxOperator },  -- muted
		CmpItemKindTypeParameter = { fg = colorscheme.specialKeyword },  -- lightPurple
		CmpItemKindCopilot = { fg = colorscheme.linkText },  -- blue
	}
end

return M

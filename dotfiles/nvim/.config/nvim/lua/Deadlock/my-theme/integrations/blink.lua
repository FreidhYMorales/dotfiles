local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	local float_bg = colorscheme.floatingWindowBackground
	return {
		-- ── Completion menu ────────────────────────────────────────────────────────
		BlinkCmpMenu          = { fg = colorscheme.mainText, bg = float_bg },
		BlinkCmpMenuBorder    = { fg = colorscheme.emphasisText, bg = float_bg },
		BlinkCmpMenuSelection = { bg = colorscheme.menuOptionBackground, fg = colorscheme.emphasisText },

		-- ── Scrollbar ──────────────────────────────────────────────────────────────
		BlinkCmpScrollBarThumb  = { bg = colorscheme.emphasisText },
		BlinkCmpScrollBarGutter = { bg = colorscheme.windowBorder },

		-- ── Labels ────────────────────────────────────────────────────────────────
		BlinkCmpLabel            = { fg = colorscheme.mainText },
		BlinkCmpLabelDeprecated  = { fg = colorscheme.inactiveText, strikethrough = true },
		BlinkCmpLabelMatch       = { fg = colorscheme.linkText, bold = true },
		BlinkCmpLabelDetail      = { fg = colorscheme.commentText },
		BlinkCmpLabelDescription = { fg = colorscheme.commentText },

		-- ── Documentation window ──────────────────────────────────────────────────
		BlinkCmpDoc              = { fg = colorscheme.mainText, bg = float_bg },
		BlinkCmpDocBorder        = { fg = colorscheme.emphasisText, bg = float_bg },
		BlinkCmpDocSeparator     = { fg = colorscheme.windowBorder, bg = float_bg },
		BlinkCmpDocCursorLine    = { bg = colorscheme.menuOptionBackground },

		-- ── Ghost text (inline preview) ───────────────────────────────────────────
		BlinkCmpGhostText = { fg = colorscheme.inactiveText, italic = true },

		-- ── Signature help ────────────────────────────────────────────────────────
		BlinkCmpSignatureHelpBorder          = { fg = colorscheme.emphasisText, bg = float_bg },
		BlinkCmpSignatureHelpActiveParameter = { fg = colorscheme.warningText, bold = true },

		-- ── Completion item kinds ─────────────────────────────────────────────────
		BlinkCmpKind           = { fg = colorscheme.syntaxFunction },
		BlinkCmpKindText       = { fg = colorscheme.mainText },
		BlinkCmpKindMethod     = { fg = colorscheme.syntaxFunction },
		BlinkCmpKindFunction   = { fg = colorscheme.syntaxFunction },
		BlinkCmpKindConstructor = { fg = colorscheme.specialKeyword },
		BlinkCmpKindField      = { fg = colorscheme.property },
		BlinkCmpKindVariable   = { fg = colorscheme.mainText },
		BlinkCmpKindClass      = { fg = colorscheme.specialKeyword },
		BlinkCmpKindInterface  = { fg = colorscheme.syntaxLightBlue },
		BlinkCmpKindModule     = { fg = colorscheme.specialKeyword },
		BlinkCmpKindProperty   = { fg = colorscheme.property },
		BlinkCmpKindUnit       = { fg = colorscheme.warningText },
		BlinkCmpKindValue      = { fg = colorscheme.lightRed },
		BlinkCmpKindEnum       = { fg = colorscheme.specialKeyword },
		BlinkCmpKindKeyword    = { fg = colorscheme.syntaxKeyword },
		BlinkCmpKindSnippet    = { fg = colorscheme.stringText },
		BlinkCmpKindColor      = { fg = colorscheme.warningText },
		BlinkCmpKindFile       = { fg = colorscheme.linkText },
		BlinkCmpKindReference  = { fg = colorscheme.linkText },
		BlinkCmpKindFolder     = { fg = colorscheme.linkText },
		BlinkCmpKindEnumMember = { fg = colorscheme.lightRed },
		BlinkCmpKindConstant   = { fg = colorscheme.lightRed },
		BlinkCmpKindStruct     = { fg = colorscheme.specialKeyword },
		BlinkCmpKindEvent      = { fg = colorscheme.warningText },
		BlinkCmpKindOperator   = { fg = colorscheme.syntaxOperator },
		BlinkCmpKindTypeParameter = { fg = colorscheme.specialKeyword },
		BlinkCmpKindCopilot    = { fg = colorscheme.linkText },
	}
end

return M

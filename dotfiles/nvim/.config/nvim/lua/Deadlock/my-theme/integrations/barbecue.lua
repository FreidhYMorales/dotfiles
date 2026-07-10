local colorscheme = require("Deadlock.my-theme.colorscheme")

local M = {}

function M.highlights()
	local bg = colorscheme.is_transparent and "NONE" or colorscheme.editorBackground

	-- ── Navic icons (barbecue depends on nvim-navic for LSP context) ────────────
	-- Colors mirror the Night Wolf syntax palette so icons feel native.
	local navic_icons = {
		NavicIconsFile          = { fg = colorscheme.mainText },
		NavicIconsModule        = { fg = colorscheme.syntaxKeyword },
		NavicIconsNamespace     = { fg = colorscheme.syntaxKeyword },
		NavicIconsPackage       = { fg = colorscheme.syntaxKeyword },
		NavicIconsClass         = { fg = colorscheme.syntaxFunction },
		NavicIconsMethod        = { fg = colorscheme.syntaxFunction },
		NavicIconsProperty      = { fg = colorscheme.property },
		NavicIconsField         = { fg = colorscheme.property },
		NavicIconsConstructor   = { fg = colorscheme.syntaxFunction },
		NavicIconsEnum          = { fg = colorscheme.specialKeyword },
		NavicIconsInterface     = { fg = colorscheme.syntaxLightBlue },
		NavicIconsFunction      = { fg = colorscheme.syntaxFunction },
		NavicIconsVariable      = { fg = colorscheme.warningText },
		NavicIconsConstant      = { fg = colorscheme.lightRed },
		NavicIconsString        = { fg = colorscheme.stringText },
		NavicIconsNumber        = { fg = colorscheme.warningEmphasis },
		NavicIconsBoolean       = { fg = colorscheme.lightRed },
		NavicIconsArray         = { fg = colorscheme.warningText },
		NavicIconsObject        = { fg = colorscheme.warningText },
		NavicIconsKey           = { fg = colorscheme.warningText },
		NavicIconsNull          = { fg = colorscheme.lightRed },
		NavicIconsEnumMember    = { fg = colorscheme.lightRed },
		NavicIconsStruct        = { fg = colorscheme.specialKeyword },
		NavicIconsEvent         = { fg = colorscheme.specialKeyword },
		NavicIconsOperator      = { fg = colorscheme.lightRed },
		NavicIconsTypeParameter = { fg = colorscheme.warningText },
		NavicText               = { fg = colorscheme.mainText,     bg = bg },
		NavicSeparator          = { fg = colorscheme.inactiveText, bg = bg },
	}

	-- ── Barbecue winbar ──────────────────────────────────────────────────────────
	local barbecue = {
		-- Base winbar background; transparent variants leave bg untouched
		BarbecueNormal    = { fg = colorscheme.mainText,     bg = bg },
		-- Dimmed parts (parent directories, ellipsis)
		BarbecueDimmed    = { fg = colorscheme.inactiveText, bg = bg },
		BarbecueEllipsis  = { fg = colorscheme.inactiveText, bg = bg },
		BarbecueSeparator = { fg = colorscheme.inactiveText, bg = bg },
		-- Path segments
		BarbecueDirname   = { fg = colorscheme.inactiveText, bg = bg },
		BarbecueBasename  = { fg = colorscheme.emphasisText,  bg = bg, bold = true },
		-- Breadcrumb context text
		BarbecueContext   = { fg = colorscheme.mainText,     bg = bg },
		-- Modified indicator (● or similar marker shown when buffer is unsaved)
		BarbecueModified  = { fg = colorscheme.warningEmphasis, bg = bg },

		-- ── Per-kind context icon overrides ──────────────────────────────────────
		-- These let barbecue colour its own context icons independently of navic.
		BarbecueContextFile          = { fg = colorscheme.mainText },
		BarbecueContextModule        = { fg = colorscheme.syntaxKeyword },
		BarbecueContextNamespace     = { fg = colorscheme.syntaxKeyword },
		BarbecueContextPackage       = { fg = colorscheme.syntaxKeyword },
		BarbecueContextClass         = { fg = colorscheme.syntaxFunction },
		BarbecueContextMethod        = { fg = colorscheme.syntaxFunction },
		BarbecueContextProperty      = { fg = colorscheme.property },
		BarbecueContextField         = { fg = colorscheme.property },
		BarbecueContextConstructor   = { fg = colorscheme.syntaxFunction },
		BarbecueContextEnum          = { fg = colorscheme.specialKeyword },
		BarbecueContextInterface     = { fg = colorscheme.syntaxLightBlue },
		BarbecueContextFunction      = { fg = colorscheme.syntaxFunction },
		BarbecueContextVariable      = { fg = colorscheme.warningText },
		BarbecueContextConstant      = { fg = colorscheme.lightRed },
		BarbecueContextString        = { fg = colorscheme.stringText },
		BarbecueContextNumber        = { fg = colorscheme.warningEmphasis },
		BarbecueContextBoolean       = { fg = colorscheme.lightRed },
		BarbecueContextArray         = { fg = colorscheme.warningText },
		BarbecueContextObject        = { fg = colorscheme.warningText },
		BarbecueContextKey           = { fg = colorscheme.warningText },
		BarbecueContextNull          = { fg = colorscheme.lightRed },
		BarbecueContextEnumMember    = { fg = colorscheme.lightRed },
		BarbecueContextStruct        = { fg = colorscheme.specialKeyword },
		BarbecueContextEvent         = { fg = colorscheme.specialKeyword },
		BarbecueContextOperator      = { fg = colorscheme.lightRed },
		BarbecueContextTypeParameter = { fg = colorscheme.warningText },
	}

	return vim.tbl_extend("force", navic_icons, barbecue)
end

return M

-- Brackets after accepting a function completion come from blink.cmp
-- (completion.accept.auto_brackets, on by default) — no nvim-cmp hook needed.
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {
		check_ts = true, -- treesitter enabled
		ts_config = {
			lua = { "string" }, -- don't add pairs in lua string treesitter nodes
			java = false, -- don't check treesitter on java
		},
	},
}

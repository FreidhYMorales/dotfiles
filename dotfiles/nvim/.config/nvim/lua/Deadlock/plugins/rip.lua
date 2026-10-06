return {
	"chrisgrieser/nvim-rip-substitute",
	cmd = "RipSubstitute",
	-- setup() must run (README spec): enables setup-only behavior and warnings
	opts = {},
	keys = {
		{
			"<leader>fs",
			function()
				require("rip-substitute").sub()
			end,
			mode = { "n", "x" },
			desc = " rip substitute",
		},
	},
}

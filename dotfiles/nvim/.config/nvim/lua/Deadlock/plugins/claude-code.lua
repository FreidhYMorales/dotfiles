return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	opts = {
		terminal = {
			split_side = "left",
			split_width_percentage = 0.30,
			provider = "snacks",
			-- Add <leader>ac in terminal mode so the toggle works from inside the terminal.
			-- This is buffer-local so it only intercepts that key sequence in the Claude window.
			snacks_win_opts = {
				keys = {
					claude_toggle = {
						"<leader>ac",
						function()
							vim.cmd("ClaudeCode")
						end,
						mode = "t",
						desc = "Toggle Claude terminal",
					},
				},
			},
		},
	},
	keys = {
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle" },
		{ "<leader>acf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus" },
		{ "<leader>acr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume" },
		{ "<leader>acc", "<cmd>ClaudeCode --continue<cr>", desc = "Continue" },
		{ "<leader>acm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
		{ "<leader>acb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer" },
		{ "<leader>acs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		{
			"<leader>acs",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
		},
		{ "<leader>aca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>acd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		{ "<leader>ack", "<cmd>ClaudeCodeContinue<cr>", desc = "Continue recent" },
		{ "<leader>acv", "<cmd>ClaudeCodeVerbose<cr>", desc = "Verbose logging" },
	},
}

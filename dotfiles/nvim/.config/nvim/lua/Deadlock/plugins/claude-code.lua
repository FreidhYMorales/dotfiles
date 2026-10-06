-- Claude Code is the only AI tool, so its keys live directly under <leader>a
-- (README layout). A nested <leader>ac* group made the <leader>ac toggle wait
-- for timeoutlen.
return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	-- Commands exist on a fresh start, before any key is pressed
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeAdd",
		"ClaudeCodeSend",
		"ClaudeCodeTreeAdd",
		"ClaudeCodeStatus",
		"ClaudeCodeStart",
		"ClaudeCodeStop",
		"ClaudeCodeOpen",
		"ClaudeCodeClose",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
		"ClaudeCodeCloseAllDiffs",
	},
	opts = {
		terminal = {
			split_side = "left",
			split_width_percentage = 0.30,
			provider = "snacks",
			-- Hide from inside the terminal. Must not start with <leader> (Space):
			-- a terminal-mode <leader> mapping delays every typed space.
			snacks_win_opts = {
				keys = {
					claude_hide = {
						"<C-,>",
						function(self)
							self:hide()
						end,
						mode = "t",
						desc = "Hide Claude terminal",
					},
				},
			},
		},
	},
	keys = {
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "x", desc = "Send selection" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "oil", "snacks_picker_list" },
		},
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}

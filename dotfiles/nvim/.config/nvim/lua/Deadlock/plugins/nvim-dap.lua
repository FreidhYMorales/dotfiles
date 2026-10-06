return {
	{
		-- Description: Debug Adapter Protocol client implementation for Neovim.
		"mfussenegger/nvim-dap",
		desc = "Debugging support. Requires language specific adapters to be configured.",

		dependencies = {
			-- Description: A UI for nvim-dap.
			{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },

			-- Description: Virtual text for the debugger.
			{
				"theHamsta/nvim-dap-virtual-text",
				opts = {},
			},
		},

		-- Keybindings for nvim-dap
		-- (the <leader>d group label lives in which-key.lua)
		keys = {
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Breakpoint Condition",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>dg",
				function()
					require("dap").goto_()
				end,
				desc = "Go to Line (No Execute)",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>dj",
				function()
					require("dap").down()
				end,
				desc = "Down",
			},
			{
				"<leader>dk",
				function()
					require("dap").up()
				end,
				desc = "Up",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dp",
				function()
					require("dap").pause()
				end,
				desc = "Pause",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>ds",
				function()
					local widgets = require("dap.ui.widgets")
					widgets.centered_float(widgets.sessions)
				end,
				desc = "Sessions",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Widgets",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle DAP UI",
			},
		},

		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Setup DAP UI
			dapui.setup()

			-- Auto open/close DAP UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Set highlight for DapStoppedLine
			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

			-- Define signs for DAP
			local dap_signs = {
				Breakpoint = { text = " ", texthl = "DiagnosticError" },
				BreakpointCondition = { text = " ", texthl = "DiagnosticError" },
				BreakpointRejected = { text = " ", texthl = "DiagnosticError" },
				LogPoint = { text = ".>", texthl = "DiagnosticInfo" },
				Stopped = { text = "󰁕 ", texthl = "DiagnosticWarn", linehl = "DapStoppedLine" },
			}

			for name, sign in pairs(dap_signs) do
				vim.fn.sign_define("Dap" .. name, sign)
			end

			-- .vscode/launch.json is read automatically on demand by nvim-dap
			-- (load_launchjs is deprecated; vim.json.decode handles comments in 0.12)

			-- codelldb adapter (Rust / C / C++)
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.rust = {
				{
					name = "Launch binary",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			-- C / C++: same adapter, any executable under cwd
			dap.configurations.cpp = {
				{
					name = "Launch executable",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			dap.configurations.c = dap.configurations.cpp
		end,
	},
}

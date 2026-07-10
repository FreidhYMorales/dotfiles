return {
  "folke/zen-mode.nvim",
  cmd = "ZenMode",
  opts = {
      plugins = {
          gitsigns = true,
          kitty = { enabled = false, font = "+2" },
          twilight = { enabled = true },
      },
  },
  keys = { {"<leader>z", "<CMD>ZenMode<CR>", desc = "Activeate/Deactivate ZenMode" } }, 
}

return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
      default_file_explorer = true,
      skip_confirm_for_simple_edits = true,
      delete_to_trash = true,
      view_options = {
          show_hidden = false,
          is_hidden_file = function(name, bufnr)
              local m = name:match("^%.")
              return m ~= nil
          end,
          natural_order = "fast",
          case_insensitive =  true,
          sort = {
              { "type" , "asc" },
              { "name" , "asc" },
          },
      },
      keymaps = {
          ["q"] = { "actions.close", mode = "n" },
          ["."] = { "actions.toggle_hidden", mode = "n" },
      },
  },
  -- Optional dependencies
  -- dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
}

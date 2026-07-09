return {
  'b0o/incline.nvim',
  config = function()
    require('incline').setup({
        render = function(props)
            local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t") -- Get the filename
            if vim.bo[props.buf].modified then
                filename = "[+] " .. filename -- Indicate if the file is modified
            end

            local icon, color = require("nvim-web-devicons").get_icon_color(filename) -- Get the icon and color for the file
            return { { icon, guifg = color }, { " " }, { filename } } -- Return the rendered content
        end,
    })
  end,
  -- Optional: Lazy load Incline
  event = 'VeryLazy',
}

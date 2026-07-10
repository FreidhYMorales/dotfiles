---@class mytheme.Highlight: vim.api.keyset.highlight
---@field style? vim.api.keyset.highlight

---@alias mytheme.Highlights table<string,mytheme.Highlight|string>

---@alias mytheme.HighlightsFn fun(colors: ColorScheme, opts:mytheme.Config):mytheme.Highlights

---@class mytheme.Cache
---@field groups mytheme.Highlights
---@field inputs table

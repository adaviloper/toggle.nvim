-- main module file
local module = require("juggle.module")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  print('hit')
  vim.api.nvim_create_user_command("ToggleSyntax", module.toggle_arrow_function_under_cursor, {})
end

return M

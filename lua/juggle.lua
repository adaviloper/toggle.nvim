local juggle_ft = require("juggle_filetypes")
local extract = require("extract_filetypes")

local juggle = {}

-- local function with_defaults(options)
--    return {
--       -- name = options.name or "John Doe"
--    }
-- end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function juggle.setup()
   -- avoid setting global values outside of this function. Global state
   -- mutations are hard to debug and test, so having them in a single
   -- function/module makes it easier to reason about all possible changes
   -- juggle.options = with_defaults(options)

   -- do here any startup your plugin needs, like creating commands and
   -- mappings that depend on values passed in options
   vim.api.nvim_create_user_command(
      "ToggleSyntax",
      juggle_ft.toggle_arrow_function_under_cursor,
      {}
   )
   vim.api.nvim_create_user_command(
      "Extract",
      extract.extract,
      {
         nargs = 1
      }
   )
end

function juggle.is_configured()
   return juggle.options ~= nil
end

-- juggle.options = nil
return juggle

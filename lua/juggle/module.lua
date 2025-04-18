---@class CustomModule
local M = {}

local ts = vim.treesitter
local query = vim.treesitter.query
local parsers = require("nvim-treesitter.parsers")

local function get_lang_from_buf(buf)
  local ft = vim.bo[buf].filetype
  if ft == "" then
    local match = require("vim.filetype").match
    ft = match({
      filename = vim.api.nvim_buf_get_name(buf),
      contents = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
    }) or ""
    vim.bo[buf].filetype = ft  -- optional: only if you want to set it
  end

  print('buf: ' .. buf)
  print('file name: ' .. vim.api.nvim_buf_get_name(buf))
  print('lang: ' .. vim.inspect(ft))
  return parsers.ft_to_lang(ft)
end

local function cursor_in_node(node, cursor_row, cursor_col)
  local sr, sc, er, ec = node:range()
  return (cursor_row > sr or (cursor_row == sr and cursor_col >= sc)) and
         (cursor_row < er or (cursor_row == er and cursor_col <= ec))
end

M.toggle_arrow_function_under_cursor = function()
  local buf = vim.api.nvim_get_current_buf() or 0
  -- local lang = ts.language.get_lang(vim.bo[buf].filetype)
  local lang = get_lang_from_buf(buf)
  local parser = parsers.get_parser(buf, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- 0-based indexing

  local access_type = "class_accessor"

  local queries = {
    class_accessor = query.parse("php", [[
      (member_access_expression
        (name) @prop
        )
  ]]),
    array_accessor = query.parse("php", [[
      (subscript_expression
        (string
          (string_content) @prop
          )
        )
  ]])
  }

  -- Find the smallest node at the cursor
  local node = root:named_descendant_for_range(row, col, row, col)
  local original_node = node

  -- Ensure we found a node and it's an arrow_function
  if not node then
    print("No node found under cursor.")
    return
  end

  -- Walk up to the arrow_function node
  while node and node:type() ~= "member_access_expression" do
    node = node:parent()
  end

  if not node then
    node = original_node
    while node and node:type() ~= "subscript_expression" do
      node = node:parent()
    end

    if not node then
      return
    end
    access_type = "array_accessor"
  end

  local q = queries[access_type]

  for _, match, _ in q:iter_matches(node, buf) do
    local prop_node
    local arrow_function_node = node -- since we walked up to it

    for id, matched_node in pairs(match) do
      local name = q.captures[id]
      if name == "prop" then
        prop_node = matched_node[1]
      end
    end

    -- Check if cursor is inside the body node
    local start_row, start_col, end_row, end_col = prop_node:range()

    if cursor_in_node(arrow_function_node, row, col) then
      if access_type ~= "array_accessor" then
        -- property → array
        local expr = "['" .. vim.treesitter.get_node_text(prop_node, buf) .. "']"


        vim.api.nvim_buf_set_text(buf, start_row, start_col - 2, end_row, end_col, { expr })
      else
        -- array → property
        if prop_node:type() == "string_content" then
          local expr = vim.treesitter.get_node_text(prop_node, buf)

          vim.api.nvim_buf_set_text(buf, start_row, start_col - 2, end_row, end_col + 2, { "->" .. expr })
          return
        end
      end

      return
    end
  end

  print("No property accessor under cursor.")
end

return M

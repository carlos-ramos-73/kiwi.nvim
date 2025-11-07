local config = require("kiwi.config")
local utils = require("kiwi.utils")

local M = {}

local set_keymaps = function(buffer_number)
  local opts = { buffer = buffer_number, noremap = true, silent = true, nowait = true }
  vim.keymap.set("v", "<CR>", M.create_or_open_wiki_file, opts)
  vim.keymap.set("n", "<CR>", M.open_link, opts)
  vim.keymap.set("n", "<Tab>", ":let @/=\"\\\\[.\\\\{-}\\\\]\"<CR>nl", opts)
end

-- Open wiki index file in the current tab
M.open_wiki_index = function(name)
  if config.folders ~= nil then
    if name ~= nil then
      for _, v in pairs(config.folders) do
        if v.name == name then
          config.path = v.path
        end
      end
    else
      utils.prompt_folder(config)
    end
  else
    require("kiwi").setup()
  end
  local wiki_index_path = vim.fs.joinpath(config.path, "index.md")
  local buffer_number = vim.fn.bufnr(wiki_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  set_keymaps(buffer_number)
end

-- Create a new Wiki entry in Journal folder on highlighting word and pressing <CR>
M.create_or_open_wiki_file = function()
  local selection_start = vim.fn.getpos("v")
  local selection_end = vim.fn.getpos(".")
  if selection_start[2] == 0 or selection_end[2] == 0 then return end -- must be valid
  if selection_start[2] ~= selection_end[2] then return end -- must be same line number
  local name = vim.fn.getregion(selection_start, selection_end)[1]
  if name == nil or name == '' then return end
  local filename = name:gsub(" ", "_"):gsub("\\", "") .. ".md"
  local new_mkdn = "[" .. name .. "]" .. "(./" .. filename .. ")"
  -- modify line
  local line = vim.fn.getline(".")
  if line == nil or line == '' then return end
  local newline = line:sub(0, selection_start[3] - 1) .. new_mkdn .. line:sub(selection_end[3] + 1, string.len(line))
  vim.api.nvim_set_current_line(newline)
  local buffer_number = vim.fn.bufnr(vim.fs.joinpath(config.path, filename), true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  set_keymaps(buffer_number)
end

-- Open a link under the cursor
M.open_link = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local filename = utils.is_link(cursor, line)
  if filename == nil or filename:len() < 2 then return end
  filename = utils.resolve_path(filename, config)
  local buffer_number = vim.fn.bufnr(filename, true)
  if buffer_number == -1 then return end
  vim.api.nvim_win_set_buf(0, buffer_number)
  set_keymaps(buffer_number)
end

return M

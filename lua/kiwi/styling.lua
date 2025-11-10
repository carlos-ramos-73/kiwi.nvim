local M = {}

local ns = vim.api.nvim_create_namespace("Kiwi")

local apply_conceal_level = function(bufnr)
  -- Conceal now
  local current_win = vim.fn.bufwinid(bufnr)
  if current_win ~= -1 then
    vim.api.nvim_set_option_value("conceallevel", 2, { win = current_win })
  end

  -- And future windows
  vim.api.nvim_create_autocmd("BufWinEnter", {
    buffer = bufnr,
    callback = function(args)
      local win = vim.fn.bufwinid(args.buf)
      if win ~= -1 then
        vim.api.nvim_set_option_value("conceallevel", 2, { win = win })
      end
    end,
    desc = "Ensure conceallevel for kiwi buffer",
  })

end

local style_links = function(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_set_hl(0, "KiwiLinK", { underline = true, sp = "#88c0d0"})
  vim.api.nvim_set_hl(0, "KiwiDeadLink", { strikethrough = true, fg = "#999999" })
  local link_pattern = "%[(.-)%]%(<?([^)>]+)>?%)"
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_dir = vim.fn.expand('%:p:h')

  for row, line in ipairs(lines) do
    local col = 1
    while true do
      local start_pos, end_pos, label, target = line:find(link_pattern, col)
      if not start_pos then break end

      -- Using [Example](./example.md)
      local bracket1_start = start_pos - 1 -- Index of '['
      local label_start = start_pos      -- Index of first char of 'label'. 'E' in the example.
      local label_end = start_pos + #label -- Index of ']'
      local rest_end = end_pos           -- Index after ')'

      -- Check dead link
      local link_path = target
      if target:sub(1, 1) ~= '/' then link_path = current_dir .. '/' .. target end
      local link_hl_group = "KiwiLink"
      if vim.fn.filereadable(link_path) == 0 then link_hl_group = "KiwiDeadLink" end


      -- Apply highlight only to the label
      vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, label_start, {
        end_col = label_end,
        hl_group = link_hl_group,
      })

      -- Hide the '['
      vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, bracket1_start, {
        end_col = label_start,
        conceal = "",
      })

      -- Hide the '](./example.md)'
      vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, label_end, {
        end_col = rest_end,
        conceal = "",
      })

      col = end_pos + 1
    end
  end
end

M.style_buffer = function(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then return end

  apply_conceal_level(bufnr)
  style_links(bufnr) -- immeadiately highlight once

  vim.api.nvim_create_autocmd({ "BufWinEnter" ,"TextChanged", "TextChangedI" }, {
    buffer = bufnr,
    callback = function()
      style_links(bufnr)
    end,
    desc = "Style Wiki Links"
  })
end

return M

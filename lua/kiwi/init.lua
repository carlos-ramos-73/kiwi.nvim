local config = require("kiwi.config")
local utils = require("kiwi.utils")
local todo = require("kiwi.todo")
local wiki = require("kiwi.wiki")

local M = {}

-- Plug Mapping
vim.keymap.set("n", "<Plug>(KiwiOpenWikis)", function() wiki.open_wiki_index() end)
vim.keymap.set("n", "<Plug>(KiwiToggleTodo)", function() todo.toggle() end)

-- User Commands
vim.api.nvim_create_user_command("KiwiOpenWiki", function(args)
    wiki.open_wiki_index(args.args)
  end,
  {
    nargs = "?",
    desc = "Open wiki index",
  })

-- Try to remove setup function below
M.setup = function(opts)
  utils.setup(opts, config)
end

return M

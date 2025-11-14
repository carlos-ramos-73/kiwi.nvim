local utils = {}

local choose_wiki = function(folders)
  local path = ""
  local template = ""
  local list = {}
  local user_quit = false
  for i, props in pairs(folders) do
    list[i] = props.name
  end
  vim.ui.select(list, {
    prompt = 'Select wiki:',
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice == nil then
      user_quit = true
      return
    end
    for _, props in pairs(folders) do
      if props.name == choice then
        if vim.uv.fs_realpath(props.path) then
          path = props.path
        else
          path = vim.fs.joinpath(vim.loop.os_homedir(), props.path)
        end
        template = props.template
      end
    end
  end)
  return path, template, user_quit
end

-- Is placed on a valid file
local is_cursor_on_file = function(cursor, file, match_start, match_end)
  if cursor[2] >= match_start and cursor[2] <= match_end then
    if not file:match("%.md$") then
      file = file .. ".md"
    end
    return file
  end
end

-- Resolves a path string from the config into a full, absolute path.
-- @param path_str (string): The path from the configuration (e.g., "wiki" or "~/notes/wiki").
-- @return (string): The resolved absolute path.
local resolve_path = function(path_str)
	if not path_str or path_str == "" then
		return nil
	end

	local expanded_path = vim.fn.expand(path_str)

	if vim.fn.isdirectory(expanded_path) == 1 then
		return expanded_path
	end

	expanded_path = vim.fs.joinpath(vim.loop.os_homedir(), path_str)
	if vim.fn.isdirectory(expanded_path) == 1 then
	else
		pcall(vim.fn.mkdir, expanded_path, "p")
		vim.notify("  " .. expanded_path .. " is created.", vim.log.levels.WARN)
	end
	return expanded_path
end

local substitute_path = function(filename, config)
  local base_path = vim.fn.expand('%:p:h')

  if filename:sub(1, 2) == "./" then
    filename = vim.fs.joinpath(base_path, filename:sub(3, -1))
  elseif filename:sub(1, 3) == "../" then
    while filename:sub(1, 3) == "../" do
      base_path = vim.fn.fnamemodify(base_path, ":h")
      filename = filename:sub(4, -1)
    end
    if #base_path < #config.path then -- Check not to go out of this wiki
      base_path = config.path
    end
    filename = vim.fs.joinpath(base_path, filename)
  elseif filename:sub(1, 1) == "/" then
    filename = vim.fs.joinpath(config.path, filename:sub(2, -1))
    return filename -- Absolute path, no need to modify
  else
    filename = vim.fs.joinpath(base_path, filename)
  end

  return filename
end

-- Check dead link
utils.is_dead_link = function(link_path)
  local current_dir = vim.fn.expand('%:p:h')
  if link_path:sub(1, 1) ~= '/' then link_path = current_dir .. '/' .. link_path end
  if vim.fn.filereadable(link_path) == 0 then return true end
  return false
end

-- Setup wiki folder
utils.setup = function(opts, config)
	if opts and #opts > 0 then
		config.folders = opts
	else
		config.path = utils.get_wiki_path()
		config.folders = nil -- Clear folders to ensure consistent state.
	end
	utils.ensure_directories(config)
end

-- Get the default Wiki folder path
utils.get_wiki_path = function()
	local default_dir = vim.fs.joinpath(vim.loop.os_homedir(), "wiki")
	return default_dir
end

-- Create wiki folder
utils.ensure_directories = function(config)
	if config.folders ~= nil then
		for _, props in ipairs(config.folders) do
			props.path = resolve_path(props.path)
		end
	else
		config.path = resolve_path(config.path)
	end
end


-- Gets the Kiwi link under the cursor if it exists
-- @return title (string), target (string). Check both for nil, also title can be an empty string.
utils.get_kiwi_under_cursor = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  cursor[2] = cursor[2] + 1 -- because vim counts from 0 but lua from 1

  -- Pattern for [title](file)
  local pattern = "%[(.-)%]%(<?([^)>]+)>?%)"
  local start_pos = 1
  while true do
    local match_start, match_end, title, target = line:find(pattern, start_pos)
    if not match_start then break end
    start_pos = match_end + 1 -- Move past the current match
    target = is_cursor_on_file(cursor, target, match_start, match_end)
    if target then return title,target end
  end
  return nil, nil
end

-- Returns the title and target of a Kiwi link
-- i.e.: "[Example](./example.md)" -> "Example", "./example.md"
-- @param str (string): The string to analyze.
-- @return title (string), target (string). Check both for nil, also title can be an empty string.
utils.get_kiwi_title_and_link = function(str)
  local link_pattern = "%[(.-)%]%(<?([^)>]+)>?%)"
  local title, target = string.match(str, link_pattern)
  return title, target
end

-- Show prompt if multiple wiki path found or else choose default path
utils.prompt_folder = function(config)
  local did_user_quit = false
  if config.folders ~= nil then
    local count = 0
    for _ in ipairs(config.folders) do count = count + 1 end
    if count > 1 then
      config.path, config.template, did_user_quit = choose_wiki(config.folders)
      if did_user_quit then return did_user_quit end
    else
      config.path = config.folders[1].path
      config.template = config.folders[1].template
    end
    if config.template == nil then config.template = "" end
  end
  return did_user_quit
end

-- Resolves a path string from the config into a full, absolute path.
-- @param path_str (string): The path from the configuration
-- @return (string): The resolved absolute path.
utils.resolve_path = function(filename, config)
  local expanded_path = vim.fn.expand(filename)
  if vim.fn.isdirectory(expanded_path) == 1 then
    return expanded_path
  end

  return substitute_path(filename, config)
end

return utils

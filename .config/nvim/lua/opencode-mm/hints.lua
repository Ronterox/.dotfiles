-- Floating hint window module for opencode-mm Mastermind mode
-- Displays available chords and current argument buffer

local M = {}

--- State tracking for hint window
M.state = {
  win = nil,
  buf = nil
}

--- Show floating hint window with chords
-- @param chords table List of chord objects
-- @param arg_buffer string Current argument buffer content
M.show = function(chords, arg_buffer)
  M.hide()

  local lines = {}
  local max_width = 3

  -- Add chord entries
  for _, chord in ipairs(chords) do
    local prefix = string.format("  %s : ", chord.key)
    local text = chord.has_arg and string.gsub(chord.text, "$arg", "$arg") or chord.text
    table.insert(lines, prefix .. text)

    if #prefix + #text > max_width then
      max_width = #prefix + #text
    end
  end

  -- Add special keys
  table.insert(lines, "  i : insert mode")
  table.insert(lines, "  q : exit")
  table.insert(lines, "  <CR> : submit")

  -- Add argument buffer if present
  if arg_buffer and #arg_buffer > 0 then
    table.insert(lines, "  arg: {" .. arg_buffer .. "}")
  end

  -- Create buffer
  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)

  -- Calculate window size
  local width = max_width + 2
  local height = #lines + 2

  local config = vim.api.nvim_win_get_config(0)
  local col = math.floor(config.width * 0.4)
  local row = math.floor(config.height * 0.1)

  -- Create floating window
  M.state.win = vim.api.nvim_open_win(M.state.buf, false, {
    relative = "win",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    focusable = false,
    border = "rounded"
  })

  -- Make read-only
  vim.api.nvim_buf_set_option(M.state.buf, "modifiable", false)
  vim.api.nvim_buf_set_option(M.state.buf, "readonly", true)
  vim.api.nvim_buf_set_option(M.state.buf, "buftype", "nofile")
end

--- Update argument buffer in existing window without recreating
-- @param arg_buffer string New argument buffer content
M.update = function(arg_buffer)
  if not M.state.win or not M.state.buf then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(M.state.buf, 0, -1, false)
  local lines_to_update = {}

  -- Find and update arg line
  for i, line in ipairs(lines) do
    if line:match("^  arg: ") then
      if arg_buffer and #arg_buffer > 0 then
        lines_to_update[i] = "  arg: {" .. arg_buffer .. "}"
      else
        lines_to_update[i] = ""
      end
    end
  end

  vim.api.nvim_buf_set_option(M.state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.buf, "modifiable", false)
end

--- Hide and close floating hint window
M.hide = function()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil

  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
  end
  M.state.buf = nil
end

return M

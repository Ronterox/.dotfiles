-- Statusline integration module for opencode-mm
-- Manages statusline display during Mastermind mode

local M = {}

--- State tracking for Mastermind mode
M.state = {
  active = false,
  original_statusline = nil
}

--- Check if Mastermind mode is active
-- @return boolean True if active
M.is_active = function()
  return M.state.active
end

--- Get current mode name for statusline
-- @return string|nil "MASTERMIND" when active, nil otherwise
M.get_mode_name = function()
  return M.state.active and "MASTERMIND" or nil
end

--- Activate Mastermind mode statusline
M.activate = function()
  if M.state.active then
    return
  end

  M.state.active = true
  M.state.original_statusline = vim.wo.statusline

  local hl_group = "MastermindMode"
  if not vim.api.nvim_get_hl(0, { name = hl_group }) then
    vim.api.nvim_set_hl(0, hl_group, { bold = true, fg = "#ff6600" })
  end

  vim.wo.statusline = "%#MastermindMode# MASTERMIND %#Normal#%="
end

--- Deactivate Mastermind mode and restore original statusline
M.deactivate = function()
  if not M.state.active then
    return
  end

  M.state.active = false
  vim.wo.statusline = M.state.original_statusline or ""
  M.state.original_statusline = nil
end

--- Lualine component for integration with lualine plugin
-- @return string Mode name or empty string
M.lualine_component = function()
  local mode_name = M.get_mode_name()
  return mode_name and mode_name or ""
end

return M

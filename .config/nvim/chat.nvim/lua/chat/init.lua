local M = {}

function M.chat()
    -- Open new split window
    local term = require("harpoon.term")
    term.gotoTerminal(1)
    term.sendCommand(1, "open-codex --provider gemini\n")
    vim.api.nvim_feedkeys('i', 'n', true)
end

function M.setup()
    vim.api.nvim_create_user_command('Chat', M.chat, {})
end

return M

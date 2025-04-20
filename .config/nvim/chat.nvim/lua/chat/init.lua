local M = {}
local links = {
    DeepSeek='https://chat.deepseek.com/',
    Claude='https://claude.ai/new',
    ChatGPT='https://chat.openai.com/',
}

function M.chat(args)
    local name = args.args

    if links[name] ~= nil then
        M.chat_browser(links[name])
        return
    end

    local term = require("harpoon.term")
    term.gotoTerminal(1)
    term.sendCommand(1, "clear && open-codex --provider gemini\n")
    vim.api.nvim_feedkeys('i', 'n', true)
end

function M.chat_browser(url)
    if url == nil then return end

    local term = require("harpoon.term")
    term.sendCommand(1, "open " .. url .. "\n")
    print("Opening on browser " .. url)
end

function M.setup()
    vim.api.nvim_create_user_command('Chat', M.chat, { nargs = '?' })
end

return M

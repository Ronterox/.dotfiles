local M = {}
local links = {
    DeepSeek = 'https://chat.deepseek.com/',
    Claude = 'https://claude.ai/new/',
    ChatGPT = 'https://chat.openai.com/',
}


function M.chat(args)
    local name = args.args

    if links[name] ~= nil then
        vim.ui.input({ prompt = "What's the query?" }, function(input)
            if input == nil then return end
            M.chatBrowser(links[name], input)
        end)
        return
    end

    local term = require("harpoon.term")
    term.gotoTerminal(1)
    term.sendCommand(1, "clear && open-codex --provider gemini\n")
    vim.api.nvim_feedkeys('i', 'n', true)
end

local function textEncode(query)
    return string.gsub(query, "[^%w%-%_%.%~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

function M.chatBrowser(url, query)
    if query ~= "" then
        url = url .. "?q="
        query = textEncode(query)
    end

    url = url .. query
    vim.fn.system({ "open", url })
    print("Opening on browser " .. url)
end

function M.setup()
    vim.api.nvim_create_user_command('Chat', M.chat, { nargs = '?' })
end

return M

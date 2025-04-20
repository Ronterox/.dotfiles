return {
    dir = '~/.config/nvim/chat.nvim',
    cmd = { 'Chat' },
    config = true,
    keys = {
        { '<leader>co', vim.cmd.Chat, mode = { 'n' }, desc = "Open Chat with Local LLM" },
        { '<leader>cg', "<CMD>Chat ChatGPT<CR>", mode = { 'n' }, desc = "Chat With GPT" },
        { '<leader>cc', "<CMD>Chat Claude<CR>", mode = { 'n' }, desc = "Chat With Claude" },
        { '<leader>cs', "<CMD>Chat DeepSeek<CR>", mode = { 'n' }, desc = "Chat With Deepseek" },
    }
}

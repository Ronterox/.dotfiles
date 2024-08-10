return {
    'Exafunction/codeium.vim',
    enabled = true,
    event = { 'BufEnter' },
    cmd = 'Codeium',
    keys = { { '<leader>c', vim.fn['codeium#Chat'], mode = { 'n' }, desc = "Chat With Codeium" } },
    config = function()
        vim.keymap.set('i', '<Tab>', function() return vim.fn['codeium#Accept']() end, { expr = true })
    end
}

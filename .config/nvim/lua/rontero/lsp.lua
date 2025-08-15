vim.lsp.config('pinescript', {
    cmd = { 'pinescript-lsp', '--stdio' },
    filetypes = { 'pinescript' },
    root_markers = { '.git' },
})

vim.lsp.enable('pinescript')

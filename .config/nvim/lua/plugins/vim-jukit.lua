local function run_interactive_shell(shell_cmd)
    vim.g.jukit_shell_cmd = shell_cmd
    vim.cmd.JukitOut('conda activate data')
end

return {
    'luk400/vim-jukit',
    enabled = true,
    ft = { 'python', 'json', 'r' },
    config = function()
        vim.g.jukit_mappings_ext_enabled = { 'py', 'ipynb' }
        vim.g.jukit_pdf_viewer = 'xdg-open'
        vim.g.jukit_mappings = 0

        vim.keymap.set('n', '<leader>ip', function() run_interactive_shell('ipython') end)
        vim.keymap.set('n', '<leader>ir', function() run_interactive_shell('jupyter console --kernel=ir') end)

        vim.keymap.set('n', '<leader><CR>', '<Cmd>call jukit#send#section(0) | call jukit#cells#jump_to_next_cell()<CR>')
        vim.keymap.set('n', '<leader><leader>', '<Cmd>call jukit#send#section(0)<CR>')

        vim.keymap.set('n', '<CR>', '<Cmd>call jukit#send#line()<CR>')
        vim.keymap.set('v', '<CR>', '<Cmd>call jukit#send#selection()<CR>')

        vim.keymap.set('n', '<leader>all', '<Cmd>call jukit#send#all()<CR>')

        vim.keymap.set('n', '<leader>np', '<Cmd>call jukit#convert#notebook_convert(g:jukit_notebook_viewer)<CR>')

        -- Create new code cell below. Argument: Whether to create code cell (0) or markdown cell (1)
        vim.keymap.set('n', '<leader>co', ':call jukit#cells#create_below(0)<cr>')
        vim.keymap.set('n', '<leader>cO', ':call jukit#cells#create_above(0)<cr>')

        vim.keymap.set('n', '<leader>ct', ':call jukit#cells#create_below(1)<cr>')
        vim.keymap.set('n', '<leader>cT', ':call jukit#cells#create_above(1)<cr>')

        vim.keymap.set('n', '<leader>cd', ':call jukit#cells#delete()<cr>')
    end,
}

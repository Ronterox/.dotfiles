local function show_tree()
    vim.cmd.UndotreeToggle()
    vim.cmd.UndotreeFocus()
end

return {
    'mbbill/undotree',
    keys = { { '<leader>u', show_tree, mode = { 'n' } } }
}

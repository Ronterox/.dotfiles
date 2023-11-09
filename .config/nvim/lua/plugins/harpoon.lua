function GotoTerminal()
    local term = require("harpoon.term")
    term.gotoTerminal(1)
    SendKeys("i")
    return term
end

return {
    'ThePrimeagen/harpoon',
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { '<leader>a', ':lua require("harpoon.mark").add_file()<CR>',        mode = { 'n' }, desc = "Add File Harpoon" },
        { '<C-e>',     ':lua require("harpoon.ui").toggle_quick_menu()<CR>', mode = { 'n' }, desc = "Quick Menu Harpoon" },
        { '<C-l>',     ':lua require("harpoon.ui").nav_next()<CR>',          mode = { 'n' }, desc = "Nav Next Harpoon" },
        { '<C-h>',     ':lua require("harpoon.ui").nav_prev()<CR>',          mode = { 'n' }, desc = "Nav Prev Harpoon" },
        { '<leader>h', ':lua require("harpoon.ui").nav_file(1)<CR>',         mode = { 'n' }, desc = "Nav File 1 Harpoon" },
        { '<leader>j', ':lua require("harpoon.ui").nav_file(2)<CR>',         mode = { 'n' }, desc = "Nav File 2 Harpoon" },
        { '<leader>k', ':lua require("harpoon.ui").nav_file(3)<CR>',         mode = { 'n' }, desc = "Nav File 3 Harpoon" },
        { '<leader>l', ':lua require("harpoon.ui").nav_file(4)<CR>',         mode = { 'n' }, desc = "Nav File 4 Harpoon" },
        { '?',         ':lua GotoTerminal().sendCommand(1, "? ")<CR>',       mode = { 'n' }, desc = "Lynx Search" },
        { '<C-t>',     ':lua GotoTerminal()<CR>',                            mode = { 'n' }, desc = "Open Terminal" },
        { '<C-t>',     '<C-\\><C-n>:e#<CR>',                                 mode = { 't' }, desc = "Close Terminal" },
    }
}

vim.keymap.set('n', '<leader>yy', 'V"+y', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>x', ':!chmod +x %<CR>')

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'J', 'mzJ`z')

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('x', '<leader>p', '"_dP')
vim.keymap.set('n', '<leader>d', '"_d')
vim.keymap.set('v', '<leader>d', '"_d')

vim.keymap.set('n', 'Q', '<nop>') -- Don't know why, but don't press Q
vim.keymap.set('n', '<leader>r', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<left><left><left>')
vim.keymap.set('v', '<leader>r', 'y:%s/\\V<C-r>0/<C-r>0/gI<left><left><left>')

vim.keymap.set('n', '<leader>bdd', ':bd<CR>')
vim.keymap.set('n', '<leader>bda', ':%bd|e#|bd#<CR>')
vim.keymap.set('n', '<C-j>', ':bprevious<CR>zz')
vim.keymap.set('n', '<C-k>', ':bnext<CR>zz')
vim.keymap.set('n', '<C-q>', ':e#<CR>')

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

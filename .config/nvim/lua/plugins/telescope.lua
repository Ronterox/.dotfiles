local function change_cwd(key)
    require('telescope._extensions.file_browser.actions').change_cwd(key)
    vim.cmd('q!')
    vim.cmd.Neotree('current')
end

return {
    'nvim-telescope/telescope.nvim',
    dependencies = { { 'nvim-lua/plenary.nvim' }, { 'nvim-telescope/telescope-file-browser.nvim' } },
    keys = {
        {
            '<leader>ch',
            '<Cmd>Telescope keymaps<CR>',
            mode = { 'n' },
            desc = "Find Keymaps"
        },
        {
            '<leader>ff',
            '<Cmd>Telescope find_files<CR>',
            mode = { 'n' },
            desc = "Find Files"
        },
        {
            '<leader>fg',
            '<Cmd>Telescope live_grep<CR>',
            mode = { 'n' },
            desc = "Find Grep"
        },
        {
            '<leader>fh',
            '<Cmd>Telescope help_tags<CR>',
            mode = { 'n' },
            desc = "Find Help"
        },
        {
            '<leader>fp',
            ':Telescope file_browser depth=2 path=~/Documents/Projects<CR>',
            mode = { 'n' },
            desc = "Find Project"
        },
        {
            '<leader>fc',
            ':Telescope file_browser depth=3 path=~/.config/nvim<CR>',
            mode = { 'n' },
            desc = "Find Config"
        }
    },
    cmd = { 'Telescope' },
    opts = {
        defaults = { layout_config = { horizontal = { preview_cutoff = 0 } } },
        extensions = {
            file_browser = {
                cwd = vim.loop.cwd(),
                mappings = {
                    ["i"] = { ["<C-t>"] = change_cwd },
                    ["n"] = { ["t"] = change_cwd },
                },
                display_stat = false,
                hide_parent_dir = true,
                preview = { ls_short = true }
            }
        }
    },
    config = function(_, opts)
        require('telescope').setup(opts)
        require('telescope').load_extension('file_browser')
    end
}

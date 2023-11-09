return {
    -- Beautify Vim
    {
        'Mofiqul/vscode.nvim',
        opts = {
            transparent = true,
            color_overrides = {
                vscYellow = '#e46c8e',
                vscOrange = '#DCDCAA',
                vscBlueGreen = '#56C5D6'
            },
            group_overrides = {
                LineNr                = { fg = '#DCDCAA' },
                DiagnosticUnnecessary = { fg = '#5a5a5a' },
            }
        }
    },
    'stevearc/dressing.nvim',
    { 'rhysd/clever-f.vim' },

    -- Code Highlighting
    'chaimleib/vim-renpy',
    -- https://github.com/AVagueNumberOfHumans/renpyls

    'fladson/vim-kitty',
    {
        'norcalli/nvim-colorizer.lua',
        event = { "VeryLazy", "BufReadPre" },
        config = function() require 'colorizer'.setup() end
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        event = "VeryLazy",
        config = function() require 'ibl'.setup() end
    },

    -- Tracking Tools
    'wakatime/vim-wakatime',

    -- 'tpope/vim-obsession' -- Session Management
    -- Also tpope, is like the god of vim plugins <- I didn't write this, but I agree with it

    -- Fast Typing
    { "windwp/nvim-autopairs",        event = "VeryLazy",                                  config = true },
    { 'numToStr/Comment.nvim',        event = "VeryLazy",                                  config = true },

    -- File Previewer
    { "iamcco/markdown-preview.nvim", build = function() vim.fn["mkdp#util#install"]() end },
}

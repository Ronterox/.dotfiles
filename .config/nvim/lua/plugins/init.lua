return {
    -- Discord Presence
    { 'andweeb/presence.nvim', event = "InsertCharPre" },

    -- Sonic Pi
    {
        'magicmonty/sonicpi.nvim',
        requires = { 'hrsh7th/nvim-cmp', 'kyazdani42/nvim-web-devicons' },
        config = function()
            local sonicpi = require('sonicpi')
            sonicpi.setup({ lsp_diagnostics = true, })
        end,
        ft = 'sonicpi'
    },


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

    -- Smart basics of vim
    { 'rhysd/clever-f.vim',    keys = 'f' },
    { 'tpope/vim-surround',    keys = { "cs", "ds", "yss" } },

    -- Code Highlighting
    { 'chaimleib/vim-renpy',   ft = 'renpy' },
    -- https://github.com/AVagueNumberOfHumans/renpyls

    { 'fladson/vim-kitty',     ft = 'kitty' },
    {
        'norcalli/nvim-colorizer.lua',
        event = { "VeryLazy", "BufReadPre" },
        config = function() require 'colorizer'.setup() end
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        event = { "VeryLazy", "BufReadPre" },
        config = function() require 'ibl'.setup() end
    },

    -- Tracking Tools
    { 'wakatime/vim-wakatime' },

    -- 'tpope/vim-obsession' -- Session Management
    -- Also tpope, is like the god of vim plugins <- I didn't write this, but I agree with it

    {
        "apple/pkl-neovim",
        as = "pkl",
        event = {
            "BufReadPre *.pkl",
            "BufReadPre *.pcf",
            "BufReadPre PklProject",
        },
    },

    -- Fast Typing
    { "windwp/nvim-autopairs",        event = "InsertCharPre",               config = true },
    { 'numToStr/Comment.nvim',        keys = { "gc", { "gc", mode = "v" } }, config = true },

    -- File Previewer
    { "iamcco/markdown-preview.nvim", ft = 'markdown',                       build = function() vim.fn
            ["mkdp#util#install"]() end },
}

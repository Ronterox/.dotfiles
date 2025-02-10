return {
    {
        "S1M0N38/love2d.nvim",
        cmd = "LoveRun",
        enabled = false,
        ft = 'lua',
        keys = {
            { '<leader>v',  ft = 'lua',                          desc = 'LÖVE' },
            { '<leader>vv', '<CMD>LoveRun<CR>',                  ft = 'lua',   desc = 'Run LÖVE' },
            { '<leader>vs', '<CMD>LoveStop<CR>',                 ft = 'lua',   desc = 'Stop LÖVE' },
            { '<F5>',       '<CMD>LoveStop<CR><CMD>LoveRun<CR>', ft = 'lua',   desc = 'Rerun LÖVE' },
        },
    },

    -- TODO: Organize everything on their own stuff
    {
        "monkoose/DoNe",
        lazy = true,
        event = { 'BufReadPre *.script' },
        -- optional configuration
        config = function()
            -- as example adding some keybindings
            vim.keymap.set('n', '<F5>', '<Cmd>DoNe build<CR>')
            vim.keymap.set('n', '<F6>', '<Cmd>DoNe reload<CR>')
            --- ...
        end,
    },

    -- Remote Connection

    -- Obligatory
    -- remote_host     example.com # remote host to connect (must have ssh enabled)
    -- remote_path     ~/temp/ # remote folder to be synced
    -- Optional
    -- remote_user    john # username to connect with
    -- remote_port    22 # remote ssh port to connect to (default is 22)
    -- remote_passwd  secret # password to connect with (requires sshpass) (needed if not using ssh-keys)
    -- local_path    /home/ken/temp/vuetest/ # local folder to be synced (defaults to folder of .vim-arsync)
    -- ignore_path     ["build/","test/"] # list of ingored files/folders
    -- ignore_dotfiles 1 # set to 1 to not sync dotfiles (e.g. .vim-arsync)
    -- auto_sync_up    0 # set to 1 for activating automatic upload syncing on file save
    -- remote_or_local remote # set to 'local' if you want to perform syncing locally
    -- sleep_before_sync 0 # set to x seconds if you want to sleep before sync (like compiling a file before syncing)
    {
        'kenn7/vim-arsync',
        cond = vim.fn.filereadable('.vim-arsync') == 1,
        dependencies = { 'prabirshrestha/async.vim' },
    },

    { 'gpanders/nvim-parinfer' },

    -- Apple Pkl Generate Config Files
    {
        'apple/pkl-neovim',
        as = 'pkl',
        event = {
            'BufReadPre *.pkl',
            'BufReadPre *.pcf',
            'BufReadPre PklProject',
        },
    },

    -- Discord Presence
    { 'andweeb/presence.nvim', event = "InsertCharPre" },

    -- Sonic Pi
    {
        'magicmonty/sonicpi.nvim',
        dependencies = { 'hrsh7th/nvim-cmp', 'kyazdani42/nvim-web-devicons' },
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
    { 'rhysd/clever-f.vim',  keys = 'f' },
    { 'tpope/vim-surround',  keys = { "cs", "ds", "yss" } },

    -- Code Highlighting
    { 'chaimleib/vim-renpy', ft = 'renpy' },
    -- https://github.com/AVagueNumberOfHumans/renpyls

    { 'fladson/vim-kitty',   ft = 'kitty' },
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

    -- Fast Typing
    { "windwp/nvim-autopairs", event = "InsertCharPre",               config = true },
    { 'numToStr/Comment.nvim', keys = { "gc", { "gc", mode = "v" } }, config = true },

    -- File Previewer
    {
        "iamcco/markdown-preview.nvim",
        ft = 'markdown',
        build = function()
            vim.fn["mkdp#util#install"]()
        end
    },
}

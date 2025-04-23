return {
    {
        'olimorris/codecompanion.nvim',
        opts = {},
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        keys = {
            { '<leader>qf', "<CMD>CodeCompanion<CR>",     mode = { 'n' }, desc = "Quick Fix Code Companion" },
            { '<leader>cc', "<CMD>CodeCompanionChat<CR>", mode = { 'n' }, desc = "Code Companion Chat" },
        },
        config = function()
            require("codecompanion").setup({
                strategies = {
                    chat = {
                        adapter = "gemini",
                    },
                    inline = {
                        adapter = "gemini",
                    },
                },
            })
            vim.cmd([[cab cc CodeCompanion]])
        end
    },

    {
        'supermaven-inc/supermaven-nvim',
        config = function()
            require('supermaven-nvim').setup({
                keymaps = {
                    accept_suggestion = "<Tab>",
                    clear_suggestion = "<C-]>",
                    accept_word = "<C-j>",
                },
                color = {
                    suggestion = '#8a8a8a',
                    cterm = '244',
                },
            })
        end,
    },
}

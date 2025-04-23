return {
    {
        'olimorris/codecompanion.nvim',
        opts = {},
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
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

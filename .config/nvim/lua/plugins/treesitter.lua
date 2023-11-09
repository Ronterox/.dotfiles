return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "VeryLazy" },
    dependencies = {
        { 'p00f/nvim-ts-rainbow' },
        { "nvim-treesitter/nvim-treesitter-textobjects" }
    },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
        { "<C-space>", desc = "Increment selection" },
        { "<bs>",      desc = "Decrement selection", mode = "x" },
    },
    opts = {
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false
        },
        indent = { enable = true },
        ensure_installed = { "vim", "vimdoc", "c", "lua", "markdown", "json" },
        auto_install = true,
        sync_install = false,
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<C-space>",
                node_incremental = "<C-space>",
                scope_incremental = false,
                node_decremental = "<bs>",
            },
        },
        textobjects = {
            move = {
                enable = true,
                goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
                goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
                goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
                goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
            },
        },
        rainbow = {
            enable = true,
            extended_mode = true,
        }
    },
    config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
}

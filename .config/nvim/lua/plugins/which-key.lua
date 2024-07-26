return {
    "folke/which-key.nvim",
    event = { "VeryLazy" },
    opts = {
        delay = function(ctx)
            local triggers_nowait = {
                -- marks
                "`",
                "g`",
                "g'",
                -- registers
                '"',
                "<c-r>",
                -- spelling
                "z=",
            }
            return vim.tbl_contains(triggers_nowait, ctx.keys) and 0 or 300
        end
    }
}

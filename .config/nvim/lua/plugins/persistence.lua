return {
    "folke/persistence.nvim",
    lazy = false,
    cond = vim.fn.isdirectory(vim.fn.expand("%:p")) == 1 or vim.bo.filetype == "netrw",
    config = function(_, opts)
        local pers = require("persistence")
        pers.setup(opts)
        pers.load()
    end,
    opts = {
        dir = os.getenv("HOME") .. "/.vim/persistence/", -- directory where session files are saved
        options = { "buffers", "curdir", "tabpages", "winsize", "folds" }
    }
}

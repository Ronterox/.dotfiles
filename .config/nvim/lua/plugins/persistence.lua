return {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    cond = function() return vim.fn.isdirectory(vim.fn.expand("%:p")) == 1 or vim.bo.filetype == "netrw" end,
    opts = {
        dir = os.getenv("HOME") .. "/.vim/persistence", -- directory where session files are saved
        options = { "buffers", "curdir", "tabpages", "winsize", "folds" }
    }
}

-- Create group to assign commands
-- "clear = true" must be set to prevent loading an
-- auto-command repeatedly every time a file is resourced
local autocmd_group = vim.api.nvim_create_augroup("Custom auto-commands", { clear = true })

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = "*",
    command = [[%s/\s\+$//e]],
    group = autocmd_group,
})

vim.api.nvim_create_autocmd('TextYankPost', {
    pattern = "*",
    desc = "Highlight yanked text",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
    group = autocmd_group
})

vim.api.nvim_create_autocmd("VimEnter", {
    group = autocmd_group,
    callback = function()
        local filepath = vim.fn.expand("%:p")
        if vim.fn.isdirectory(filepath) == 1 or vim.bo.filetype == "netrw" then require("persistence").load() end
    end,
    nested = true,
})

vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
vim.api.nvim_create_autocmd("User", {
    group = "lualine_augroup",
    pattern = "LspProgressStatusUpdated",
    callback = require("lualine").refresh,
})

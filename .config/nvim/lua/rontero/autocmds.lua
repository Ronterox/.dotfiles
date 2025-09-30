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

vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
vim.api.nvim_create_autocmd("User", {
    group = "lualine_augroup",
    pattern = "LspProgressStatusUpdated",
    callback = require("lualine").refresh,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        -- Override 'K' for this buffer only
        vim.keymap.set(
            "n",
            "K",
            "<CMD>lua require('pretty_hover').hover()<CR>",
            { buffer = bufnr, noremap = true, silent = true }
        )
    end,
})

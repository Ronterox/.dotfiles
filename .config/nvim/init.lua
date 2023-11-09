require("rontero.set")
require("rontero.lazy")
require("rontero.remap")
require("rontero.autocmds")

function SendKeys(keys)
    local mode = vim.api.nvim_get_mode().mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode, true)
end

function ColorMyPencils(colorscheme)
    colorscheme = colorscheme or "desert"
    vim.cmd.colorscheme(colorscheme)
end

ColorMyPencils('vscode')

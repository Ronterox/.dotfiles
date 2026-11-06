require("rontero.set")
require("rontero.lazy")
require("rontero.lsp")
require("rontero.remap")
require("rontero.autocmds")

-- Keep ~/.local/state/nvim/lsp.log small. The default level dumps full
-- JSON-RPC payloads (multi-KB lines) on every LSP error.
vim.lsp.set_log_level('warn')

function SendKeys(keys)
	local mode = vim.api.nvim_get_mode().mode
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode, true)
end

function ColorMyPencils(colorscheme)
	colorscheme = colorscheme or "desert"
	vim.cmd.colorscheme(colorscheme)
	vim.cmd [[ hi StatusLine guibg=NONE ]] -- lualine transparent
end

ColorMyPencils('vscode')

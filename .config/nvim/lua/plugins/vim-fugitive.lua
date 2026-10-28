-- Cursor-line blame: an AI line names its turn (aic.blame, from aigource);
-- other lines, or without aic, gitsigns' own default text.
local function blame_text(nc)
	return function(username, info)
		local ok, blame = pcall(require, 'aic.blame')
		if ok then
			return blame.format(username, info)
		end
		local key = nc and 'current_line_blame_formatter_nc' or 'current_line_blame_formatter'
		local fmt = require('gitsigns.config').schema[key].default
		local text = require('gitsigns.blame_formatter').expand_string(fmt, username, info, { self_author_text = 'You' })
		return { { text, 'GitSignsCurrentLineBlame' } }
	end
end

return {
	{
		'tpope/vim-fugitive',
		keys = { { '<leader>gt', vim.cmd.Git, mode = { 'n' } } }
	},
	{
		'lewis6991/gitsigns.nvim',
		config = function()
			require('gitsigns').setup {
				signs = {
					add          = { text = '█' },
					change       = { text = '█' },
					delete       = { text = '▄' },
					topdelete    = { text = '▀' },
					changedelete = { text = '▒' },
					untracked    = { text = '░' },
				},
				signs_staged = {
					add          = { text = '█' },
					change       = { text = '█' },
					delete       = { text = '▄' },
					topdelete    = { text = '▀' },
					changedelete = { text = '▒' },
					untracked    = { text = '░' },
				},
				current_line_blame = true,
				current_line_blame_formatter = blame_text(false),
				current_line_blame_formatter_nc = blame_text(true),
			}
		end
	}
}

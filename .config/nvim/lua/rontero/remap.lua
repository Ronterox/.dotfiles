vim.keymap.set('n', '<leader>yy', 'V"+y', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>x', ':!chmod +x %<CR>')

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'J', 'mzJ`z')

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('x', '<leader>p', '"_dP')
vim.keymap.set('n', '<leader>d', '"_d')
vim.keymap.set('v', '<leader>d', '"_d')

vim.keymap.set('n', 'Q', '<nop>') -- Don't know why, but don't press Q. Edit: I figured out why, so it stays.
vim.keymap.set('n', '<leader>r', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<left><left><left>')
vim.keymap.set('v', '<leader>r', 'y:%s/\\V<C-r>0/<C-r>0/gI<left><left><left>')

vim.keymap.set('n', '<leader>bdd', ':bd<CR>')
vim.keymap.set('n', '<leader>bda', ':%bd|e#|bd#<CR>')

vim.keymap.set('n', '<C-j>', ':bprevious<CR>zz')
vim.keymap.set('n', '<C-k>', ':bnext<CR>zz')
vim.keymap.set('n', '<C-q>', ':e#<CR>')

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

local function search_selection(register, motion)
	return function()
		vim.cmd('normal! ' .. motion)
		local selection = string.gsub(vim.fn.getreg(register), "^%s*(.-)%s*$", "%1")
		require("harpoon.term").sendCommand(1, "? '" .. selection .. "'\n")
	end
end

vim.keymap.set('n', '<leader>s', search_selection("0", "yiw"), { desc = "Search selection" })
vim.keymap.set('v', '<leader>s', search_selection("0", "y"), { desc = "Search selection" })

local function run_last_command()
	local term = require("harpoon.term")
	vim.cmd("wa")
	term.sendCommand(1, "!!\n")
	return term
end

local function run_last_command_terminal()
	local term = run_last_command()
	term.gotoTerminal(1)
	vim.api.nvim_feedkeys('G$', 'n', true)
end

vim.keymap.set('n', '<leader>O', function()
	local file = vim.fn.expand("%:p")
	run_last_command_terminal()
	vim.cmd.split(file)
	vim.cmd.resize("+8")
end, { desc = "Run last command in a new split terminal" })

vim.keymap.set('n', '<leader>o', function()
	local function window_count()
		local total = 0
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative == "" then
				total = total + 1
			end
		end
		return total
	end
	if window_count() == 1 then
		run_last_command_terminal()
	else
		run_last_command()
	end
end, { desc = "Run last command in the terminal" })

local function searchCode()
	-- vim.ui.input({ prompt = "Look for pattern:" }, function(input)
	-- 	if input == nil then return end
	-- 	vim.cmd("cgetexpr system('code vim " .. input .. "')")
	-- 	vim.cmd("cw")
	-- 	vim.cmd("only")
	-- end)
	vim.ui.input({ prompt = "Look for pattern:" }, function(input)
		if not input or input == "" then return end

		vim.fn.setqflist({}, 'r')

		local cmd = { "code", "vim", input }

		vim.system(cmd, {
			stdout = function(err, data)
				if data then
					vim.schedule(function()
						vim.fn.setqflist({}, 'a', { lines = vim.split(data, "\n", { trimempty = true }) })
						vim.cmd("cw | only")
					end)
				end
			end,
			stderr = function(err, data)
				if data then print("Error: " .. data) end
			end
		}, function(obj)
			vim.schedule(function()
				print("Search completed with exit code: " .. obj.code)
			end)
		end)
	end)
end

_G.qf_item_shortener = function(info)
	local items = vim.fn.getqflist({ id = info.id, items = 1 }).items
	local l = {}
	for i = info.start_idx, info.end_idx do
		local item = items[i]
		local fname = vim.api.nvim_buf_get_name(item.bufnr)
		local short_name = vim.fn.fnamemodify(fname, ':t')
		local str = string.format('%s |%d:%d| %s', short_name, item.lnum, item.col, item.text)
		table.insert(l, str)
	end
	return l
end

-- vim.keymap.set('n', '<leader>td', ':vimgrep /TODO/j **/*<CR>:cw<CR>')
vim.keymap.set('n', '<leader>fc', searchCode, { desc = "Search code on computer" })
vim.keymap.set('v', '<leader>sh', 'y:!<C-r>"<CR>', { desc = "Run selection as shell command" })

vim.keymap.set('n', '<leader>pp', function()
	local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local temp_file = vim.fn.tempname()
	local out_file = vim.fn.tempname()

	vim.fn.writefile(buffer_content, temp_file)
	vim.fn.system("rpreprocessor " .. temp_file .. " > " .. out_file)
	vim.fn.delete(temp_file)

	vim.cmd("e " .. out_file .. " | set filetype=" .. vim.bo.filetype)
end, { desc = "Preprocess current file with rpreprocessor" })

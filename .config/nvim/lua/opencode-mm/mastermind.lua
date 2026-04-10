--- Mastermind mode engine - chorded prompt composition mode
local M = {}

_G.opencode_mm_mastermind = _G.opencode_mm_mastermind or {
	active = false,
	arg_buffer = "",
	saved_keymaps = {},
	bufnr = nil,
	augroup = nil,
}

local state = _G.opencode_mm_mastermind

function M.enter(bufnr)
	if state.active then
		return
	end
	local buffer = require("opencode-mm.buffer")
	if not buffer.is_opencode_buf(bufnr) then
		return
	end

	state.bufnr = bufnr
	state.arg_buffer = ""
	state.active = true

	state.saved_keymaps = {}
	local existing = vim.api.nvim_buf_get_keymap(bufnr, "n")
	for _, map in ipairs(existing) do
		state.saved_keymaps[map.lhs] = {
			rhs = map.rhs or "",
			callback = map.callback,
			noremap = map.noremap == 1,
			silent = map.silent == 1,
		}
	end

	state.augroup = vim.api.nvim_create_augroup("OpenCodeMMMastermind", { clear = true })

	local chords = require("opencode-mm.chords")
	local all_chords = chords.get_all()
	for _, chord in ipairs(all_chords) do
		vim.keymap.set("n", chord.key, function()
			M._handle_chord(chord.key)
		end, { buffer = bufnr, nowait = true })
	end

	for digit = 0, 9 do
		local d = tostring(digit)
		vim.keymap.set("n", d, function()
			M._accumulate_arg(d)
		end, { buffer = bufnr, nowait = true })
	end

	vim.keymap.set("n", "i", function()
		vim.cmd("startinsert")
	end, { buffer = bufnr, nowait = true })
	vim.keymap.set("n", "q", function()
		M.exit()
	end, { buffer = bufnr, nowait = true })
	vim.keymap.set("n", "<Esc>", function()
		M.exit()
	end, { buffer = bufnr, nowait = true })
	vim.keymap.set("n", "<CR>", function()
		M._submit_and_exit()
	end, { buffer = bufnr, nowait = true })
	vim.keymap.set("n", "<Space>", function()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		vim.api.nvim_buf_set_text(state.bufnr, row - 1, col, row - 1, col, { " " })
		vim.api.nvim_win_set_cursor(0, { row, col + 1 })
	end, { buffer = bufnr, nowait = true })

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = state.augroup,
		buffer = bufnr,
		callback = function()
			if state.active then
				require("opencode-mm.hints").update(state.arg_buffer)
			end
		end,
	})

	require("opencode-mm.hints").show(all_chords, state.arg_buffer)
	require("opencode-mm.statusline").activate()
end

function M.exit()
	if not state.active then
		return
	end
	local bufnr = state.bufnr

	if state.augroup then
		pcall(vim.api.nvim_del_augroup_by_name, "OpenCodeMMMastermind")
	end

	if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
		local current = vim.api.nvim_buf_get_keymap(bufnr, "n")
		for _, map in ipairs(current) do
			pcall(vim.keymap.del, "n", map.lhs, { buffer = bufnr })
		end
		local buffer = require("opencode-mm.buffer")
		if buffer.is_opencode_buf(bufnr) then
			local conv = require("opencode-mm.conversation")
			buffer.setup_keymaps(
				bufnr,
				function()
					conv.submit(bufnr)
				end,
				function()
					conv.abort(bufnr)
				end
			)
		end
	end

	require("opencode-mm.hints").hide()
	require("opencode-mm.statusline").deactivate()

	state.active = false
	state.arg_buffer = ""
	state.saved_keymaps = {}
	state.bufnr = nil
	state.augroup = nil
end

function M._handle_chord(key)
	if not state.active or not state.bufnr then
		return
	end
	local chords = require("opencode-mm.chords")
	local text = chords.expand(key, state.arg_buffer)
	if not text then
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local text_lines = vim.split(text, "\n")
	vim.api.nvim_buf_set_text(state.bufnr, row - 1, col, row - 1, col, text_lines)
	local new_row = row + #text_lines - 1
	local new_col = col + #text_lines[#text_lines]
	vim.api.nvim_win_set_cursor(0, { new_row, new_col })

	state.arg_buffer = ""
	require("opencode-mm.hints").update("")
end

function M._accumulate_arg(digit)
	state.arg_buffer = state.arg_buffer .. digit
	require("opencode-mm.hints").update(state.arg_buffer)
end

function M._submit_and_exit()
	if state.bufnr then
		require("opencode-mm.conversation").submit(state.bufnr)
	end
	M.exit()
end

function M.is_active()
	return state.active
end

return M

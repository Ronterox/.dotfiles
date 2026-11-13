-- Ghost-text FIM completion for :terminal shells, using the llama-server that
-- llama.vim talks to. llama.vim only works in insert mode (getline/setline,
-- CursorMovedI, inoremap), so terminal mode gets this small client: the
-- scrollback above the cursor is the prefix, and accepted text is typed into
-- the shell with chansend.
--
--   <C-j>    accept suggestion (falls through when none is shown)
--   <M-l>    request now / dismiss (works in any terminal program)
--
-- Auto-trigger works in shells and in TUI prompts (opencode, codex, claude…),
-- which keep the real cursor at the end of their input. It skips editors,
-- pagers and monitors (SKIP), where keys aren't typed text.
local M = {}

local URL = 'http://127.0.0.1:8012/infill'
local DEBOUNCE_MS = 100
local N_PREFIX = 60 -- scrollback lines sent as context
-- Foreground programs (/proc comm) that get no auto-trigger.
local SKIP = {}
for _, name in ipairs({
	'vi', 'vim', 'nvim', 'nano', 'emacs', 'less', 'more', 'most', 'man',
	'top', 'htop', 'btop', 'watch', 'tig', 'lazygit', 'fzf',
}) do SKIP[name] = true end
-- Keys after which the input line is gone: Enter, C-c, C-d.
local NO_TRIGGER = { ['\r'] = true, ['\3'] = true, ['\4'] = true }

local ns = vim.api.nvim_create_namespace('llama_term')
local timer = assert(vim.uv.new_timer())
local job  -- in-flight curl (vim.SystemObj)
local hint -- { buf, row, col, line, text }

local function read(path)
	local f = io.open(path)
	if not f then return nil end
	local s = f:read('*a'); f:close()
	return s
end

local function auto_allowed(buf)
	local pid = vim.b[buf].terminal_job_pid
	local stat = pid and read('/proc/' .. pid .. '/stat')
	-- fields after "(comm)": state ppid pgrp session tty_nr tpgid
	local tpgid = stat and stat:match('%) %S+ %S+ %S+ %S+ %S+ (%d+)')
	local comm = tpgid and read('/proc/' .. tpgid .. '/comm')
	return comm ~= nil and not SKIP[vim.trim(comm)]
end

-- Cursor context, or nil when the cursor isn't at the end of the input.
local function context()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype ~= 'terminal' then return nil end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ''
	if vim.trim(line:sub(col + 1)) ~= '' then return nil end
	local first = math.max(0, row - 1 - N_PREFIX)
	local prev = vim.api.nvim_buf_get_lines(buf, first, row - 1, false)
	return {
		buf = buf,
		row = row,
		col = col,
		line = line,
		prefix = table.concat(prev, '\n') .. '\n',
		-- the line is trimmed, so a just-typed trailing space may be missing
		middle = line:sub(1, col) .. string.rep(' ', col - #line),
	}
end

local function still_at(ctx)
	if vim.api.nvim_get_mode().mode ~= 't' then return false end
	local now = context()
	return now ~= nil and now.buf == ctx.buf and now.row == ctx.row
		and now.col == ctx.col and now.line == ctx.line
end

function M.hide()
	if hint then
		pcall(vim.api.nvim_buf_clear_namespace, hint.buf, ns, 0, -1)
		hint = nil
	end
end

local function cancel()
	timer:stop()
	if job then
		job:kill('sigterm')
		job = nil
	end
end

local function show(ctx, text)
	M.hide()
	local col = math.min(ctx.col, #ctx.line)
	local pad = string.rep(' ', ctx.col - col)
	vim.api.nvim_buf_set_extmark(ctx.buf, ns, ctx.row - 1, col, {
		virt_text = { { pad .. text, 'llama_hl_fim_hint' } },
		virt_text_pos = 'overlay',
	})
	ctx.text = text
	hint = ctx
end

local function request(ctx)
	cancel()
	local body = vim.json.encode({
		input_prefix = ctx.prefix,
		input_suffix = '\n',
		input_extra = {},
		prompt = ctx.middle,
		n_predict = 48,
		stop = { '\n' },
		top_k = 40,
		top_p = 0.90,
		samplers = { 'top_k', 'top_p', 'infill' },
		cache_prompt = true,
		t_max_predict_ms = 500,
		response_fields = { 'content' },
	})
	local this
	this = vim.system({
		'curl', '--silent', '--max-time', '10', '--request', 'POST', '--url', URL,
		'--header', 'Content-Type: application/json', '--data', '@-',
	}, { stdin = body, text = true }, vim.schedule_wrap(function(out)
		if job ~= this then return end -- superseded
		job = nil
		if out.code ~= 0 then return end
		local ok, res = pcall(vim.json.decode, out.stdout)
		local text = ok and type(res) == 'table' and res.content
		if type(text) ~= 'string' then return end
		text = text:gsub('%c', ''):gsub('%s+$', '')
		if text ~= '' and still_at(ctx) then show(ctx, text) end
	end))
	job = this
end

local function auto_trigger()
	M.hide()
	if vim.api.nvim_get_mode().mode ~= 't' then return end
	local ctx = context()
	if ctx and auto_allowed(ctx.buf) then request(ctx) end
end

-- Returns true if a suggestion was sent to the shell.
local function accept()
	if not hint or not still_at(hint) then return false end
	local chan, text = vim.b[hint.buf].terminal_job_id, hint.text
	M.hide()
	vim.api.nvim_chan_send(chan, text)
	return true
end

function M.setup()
	vim.on_key(function(_, typed)
		if typed == '' or NO_TRIGGER[typed] then return end
		if vim.api.nvim_get_mode().mode ~= 't' then return end
		timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(auto_trigger))
	end, ns)

	local group = vim.api.nvim_create_augroup('llama_term', { clear = true })
	-- Typed text is echoed by the shell, so hide as soon as the line under the
	-- hint changes; the overlay would otherwise cover what was typed.
	vim.api.nvim_create_autocmd('TextChangedT', {
		group = group,
		callback = function()
			if hint and not still_at(hint) then M.hide() end
		end,
	})
	vim.api.nvim_create_autocmd({ 'TermLeave', 'BufLeave' }, {
		group = group,
		callback = function()
			cancel()
			M.hide()
		end,
	})

	vim.keymap.set('t', '<C-j>', function()
		return accept() and '' or '<C-j>'
	end, { expr = true, desc = 'llama: accept terminal suggestion' })
	vim.keymap.set('t', '<M-l>', function()
		if hint then
			cancel()
			M.hide()
			return
		end
		local ctx = context()
		if ctx then request(ctx) end
	end, { desc = 'llama: suggest in terminal' })
end

return M

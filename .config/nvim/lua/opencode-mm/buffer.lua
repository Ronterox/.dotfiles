local M = {}

M.bufs = {}
M.ns = vim.api.nvim_create_namespace("opencode_mm")

function M.is_opencode_buf(bufnr)
	return M.bufs[bufnr] ~= nil
end

function M.create(session_id)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
	vim.api.nvim_set_option_value("filetype", "opencode-mm", { buf = bufnr })
	local name = session_id and ("opencode://session/" .. session_id) or "opencode://new"
	vim.api.nvim_buf_set_name(bufnr, name)
	M.bufs[bufnr] = { session_id = session_id, win_id = nil }
	return bufnr
end

function M.open(bufnr, config)
	if not M.bufs[bufnr] then return end
	local pos = config and config.window and config.window.position or "right"
	if pos == "right" then
		vim.cmd("rightbelow vsplit")
	elseif pos == "bottom" then
		vim.cmd("rightbelow split")
	end
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, bufnr)
	vim.api.nvim_set_option_value("wrap", true, { win = win })
	vim.api.nvim_set_option_value("linebreak", true, { win = win })
	vim.api.nvim_set_option_value("conceallevel", 2, { win = win })
	M.bufs[bufnr].win_id = win
	return win
end

function M.close(bufnr)
	local info = M.bufs[bufnr]
	if not info then return end
	if info.win_id and vim.api.nvim_win_is_valid(info.win_id) then
		vim.api.nvim_win_close(info.win_id, true)
	end
	M.bufs[bufnr] = nil
end

function M.get_session_id(bufnr)
	local info = M.bufs[bufnr]
	return info and info.session_id
end

function M.set_session_id(bufnr, session_id)
	if M.bufs[bufnr] then
		M.bufs[bufnr].session_id = session_id
		vim.api.nvim_buf_set_name(bufnr, "opencode://session/" .. session_id)
	end
end

function M.parse_frontmatter(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local meta = { model = "", system = "", session = "" }
	if lines[1] ~= "---" then return meta end
	for i = 2, #lines do
		if lines[i] == "---" then break end
		local key, val = lines[i]:match("^(%w+):%s*(.*)$")
		if key and val then meta[key] = val end
	end
	return meta
end

function M.render_frontmatter(bufnr, meta)
	local lines = {
		"---",
		"model: " .. (meta.model or ""),
		"variant: " .. (meta.variant or ""),
		"system: " .. (meta.system or ""),
		"session: " .. (meta.session or ""),
		"---",
		"",
	}
	local fm_end = M._find_frontmatter_end(bufnr)
	-- Consume the blank separator after the header so re-rendering does not
	-- accumulate empty lines.
	if fm_end > 0 then
		local after = vim.api.nvim_buf_get_lines(bufnr, fm_end, fm_end + 1, false)[1]
		if after == "" then
			fm_end = fm_end + 1
		end
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, fm_end, false, lines)
	M._highlight_headers(bufnr)
end

--- Extract the editable text from a v2 session message.
--- Only user messages and assistant text parts are rendered; tool, reasoning,
--- system and idle messages are skipped.
local function message_text(msg)
	if msg.type == "user" then
		return msg.text or ""
	elseif msg.type == "assistant" then
		local texts = {}
		for _, part in ipairs(type(msg.content) == "table" and msg.content or {}) do
			if part.type == "text" and part.text and part.text ~= "" then
				table.insert(texts, part.text)
			end
		end
		return table.concat(texts, "\n")
	end
	return nil
end

function M.render_messages(bufnr, messages)
	if type(messages) ~= "table" then
		messages = {}
	end
	local fm_end = M._find_frontmatter_end(bufnr)
	local lines = {}
	local previous_role
	for _, msg in ipairs(messages) do
		local content = message_text(msg)
		if content and content ~= "" then
			local role = msg.type == "assistant" and "Assistant" or "User"
			-- v2 can emit several assistant messages per turn (one per tool
			-- step); merge consecutive same-role messages into one section.
			if role ~= previous_role then
				table.insert(lines, "### " .. role)
				previous_role = role
			end
			for line in content:gmatch("[^\n]*") do
				table.insert(lines, line)
			end
			table.insert(lines, "")
		end
	end
	vim.api.nvim_buf_set_lines(bufnr, fm_end, -1, false, lines)
	M._highlight_headers(bufnr)
end

function M.parse_messages(bufnr)
	local fm_end = M._find_frontmatter_end(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, fm_end, -1, false)
	local messages, current = {}, nil
	for i, line in ipairs(lines) do
		local role = line:match("^### (%w+)")
		if role then
			if current then table.insert(messages, current) end
			current = { role = role:lower(), content = "", line_start = fm_end + i }
		elseif current then
			current.content = current.content .. (current.content == "" and "" or "\n") .. line
			current.line_end = fm_end + i
		end
	end
	if current then table.insert(messages, current) end
	return messages
end

function M.get_pending_prompt(bufnr)
	local msgs = M.parse_messages(bufnr)
	if #msgs == 0 then return "" end
	local last = msgs[#msgs]
	return last.role == "user" and vim.trim(last.content) or ""
end

function M.set_pending_prompt(bufnr, text)
	local msgs = M.parse_messages(bufnr)
	if #msgs == 0 then return end
	local last = msgs[#msgs]
	if last.role == "user" and last.line_start and last.line_end then
		vim.api.nvim_buf_set_lines(bufnr, last.line_start, last.line_end, false, vim.split(text, "\n"))
	end
end

--- Append text to the pending (last) user section, creating one if the buffer
--- currently ends in an assistant or empty section.
function M.append_pending_prompt(bufnr, text)
	M.ensure_section(bufnr, "User")
	local msgs = M.parse_messages(bufnr)
	local last = msgs[#msgs]
	if not last or last.role ~= "user" then
		M.ensure_section(bufnr, "User")
		msgs = M.parse_messages(bufnr)
		last = msgs[#msgs]
	end
	if not last or last.role ~= "user" then
		return
	end

	local start = last.line_start
	local stop = last.line_end or last.line_start
	local lines = vim.api.nvim_buf_get_lines(bufnr, start, stop, false)
	while #lines > 0 and vim.trim(lines[#lines]) == "" do
		table.remove(lines)
	end
	for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
		table.insert(lines, line)
	end
	vim.api.nvim_buf_set_lines(bufnr, start, stop, false, lines)
	M._highlight_headers(bufnr)
end

function M.setup_keymaps(bufnr, submit_fn, abort_fn)
	local opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }
	vim.keymap.set("n", "<CR>", submit_fn, opts)
	vim.keymap.set("n", "<C-s>", submit_fn, opts)
	vim.keymap.set("i", "<C-s>", function()
		vim.cmd("stopinsert")
		submit_fn()
	end, opts)
	vim.keymap.set("n", "<C-c>", abort_fn, opts)
	vim.keymap.set("i", "<C-c>", function()
		vim.cmd("stopinsert")
	end, opts)
	vim.keymap.set("n", "<leader><leader>", function()
		require("opencode-mm.mastermind").enter(bufnr)
	end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
end

function M.last_role(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i = #lines, 1, -1 do
		local role = lines[i]:match("^### (%w+)")
		if role then
			return role:lower()
		end
	end
	return nil
end

--- Make sure the buffer ends with the requested section header.
function M.ensure_section(bufnr, role)
	if M.last_role(bufnr) == role:lower() then
		return
	end
	local lc = vim.api.nvim_buf_line_count(bufnr)
	local title = role:sub(1, 1):upper() .. role:sub(2):lower()
	vim.api.nvim_buf_set_lines(bufnr, lc, lc, false, { "", "### " .. title, "" })
	M._highlight_headers(bufnr)
end

function M._find_frontmatter_end(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)
	if lines[1] ~= "---" then return 0 end
	for i = 2, #lines do
		if lines[i] == "---" then return i end
	end
	return 0
end

function M._highlight_headers(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		if line:match("^### [Uu]ser") then
			vim.api.nvim_buf_set_extmark(bufnr, M.ns, i - 1, 0, { hl_group = "Statement", end_col = line:len() })
		elseif line:match("^### [Aa]ssistant") then
			vim.api.nvim_buf_set_extmark(bufnr, M.ns, i - 1, 0, { hl_group = "Identifier", end_col = line:len() })
		end
	end
end

return M

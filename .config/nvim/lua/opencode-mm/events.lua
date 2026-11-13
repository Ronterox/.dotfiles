--- Real-time OpenCode v2 event handling for a conversation buffer.
local M = {}

M.state = {
	streaming = {},
	streamed = {},
	thinking = {},
	reasoning_done = {},
	subscribed = {},
}

local function get_buffer()
	return require("opencode-mm.buffer")
end
local function get_stream()
	return require("opencode-mm.stream")
end

local function payload(data)
	if type(data) ~= "table" then
		return {}
	end
	local p = data.data or data.properties
	if type(p) == "table" then
		return p
	end
	return data
end

local function current_session(bufnr)
	return get_buffer().get_session_id(bufnr)
end

local function matches(bufnr, data)
	local sid = current_session(bufnr)
	return sid ~= nil and type(data) == "table" and data.sessionID == sid
end

--- Append an incremental text chunk and remember everything written for the
--- part so `*.ended` can finish or correct it.
local function append_streamed(bufnr, key, text)
	if not text or text == "" then
		return
	end
	M.state.streamed[bufnr] = M.state.streamed[bufnr] or {}
	local acc = M.state.streamed[bufnr][key] or ""
	M.state.streamed[bufnr][key] = acc .. text
	M.append_to_assistant(bufnr, text)
end

--- Apply the authoritative full text for a part, appending only what is
--- missing (or replacing the streamed text if it diverges).
local function finish_streamed(bufnr, key, full)
	if not full or full == "" then
		return
	end
	M.state.streamed[bufnr] = M.state.streamed[bufnr] or {}
	local acc = M.state.streamed[bufnr][key] or ""
	M.state.streamed[bufnr][key] = full
	if acc == full then
		return
	end
	if acc ~= "" and full:sub(1, #acc) == acc then
		M.append_to_assistant(bufnr, full:sub(#acc + 1))
		return
	end
	if #acc > 0 then
		M.trim_assistant_tail(bufnr, #acc)
	end
	M.append_to_assistant(bufnr, full)
end

--- Locate the last assistant section.
--- @return number|nil start 1-based header line
--- @return number|nil stop 1-based line after the section body
--- @return table|nil lines
local function assistant_section(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local start
	for i = #lines, 1, -1 do
		if lines[i]:match("^### [Aa]ssistant") then
			start = i
			break
		end
	end
	if not start then
		return nil
	end
	local stop = #lines + 1
	for i = start + 1, #lines do
		if lines[i]:match("^### ") then
			stop = i
			break
		end
	end
	return start, stop, lines
end

function M.append_to_assistant(bufnr, text)
	if not text or text == "" then
		return
	end
	local start, stop, lines = assistant_section(bufnr)
	if not start then
		return
	end

	local body_lines = {}
	for i = start + 1, stop - 1 do
		table.insert(body_lines, lines[i])
	end
	local body = table.concat(body_lines, "\n") .. text
	vim.api.nvim_buf_set_lines(bufnr, start, stop - 1, false, vim.split(body, "\n"))
end

--- Body text of the last assistant section.
local function assistant_body(bufnr)
	local start, stop, lines = assistant_section(bufnr)
	if not start then
		return nil
	end
	local body_lines = {}
	for i = start + 1, stop - 1 do
		table.insert(body_lines, lines[i])
	end
	return table.concat(body_lines, "\n")
end

--- Ensure a paragraph break before new content, returning the bytes added.
local function ensure_body_break(bufnr)
	local body = assistant_body(bufnr)
	if not body or body == "" then
		return 0
	end
	if body:sub(-2) == "\n\n" then
		return 0
	end
	local sep = body:sub(-1) == "\n" and "\n" or "\n\n"
	M.append_to_assistant(bufnr, sep)
	return #sep
end

--- Remove the last `nchars` bytes from the assistant section body. Used to
--- drop streamed reasoning once the real answer starts.
function M.trim_assistant_tail(bufnr, nchars)
	if not nchars or nchars <= 0 then
		return
	end
	local start, stop, lines = assistant_section(bufnr)
	if not start then
		return
	end

	local body_lines = {}
	for i = start + 1, stop - 1 do
		table.insert(body_lines, lines[i])
	end
	local body = table.concat(body_lines, "\n")
	if #body <= nchars then
		body = ""
	else
		body = body:sub(1, #body - nchars)
	end
	local new_lines = body == "" and {} or vim.split(body, "\n")
	vim.api.nvim_buf_set_lines(bufnr, start, stop - 1, false, new_lines)
end

--- Drop any reasoning text that is still visible in the assistant section.
function M.clear_thinking(bufnr)
	local thinking = M.state.thinking[bufnr]
	M.state.thinking[bufnr] = nil
	if not thinking or thinking.chars <= 0 then
		return
	end
	M.trim_assistant_tail(bufnr, thinking.chars)
end

--- Append streamed reasoning text and remember how much is on screen so it
--- can be removed when the answer arrives.
local function append_thinking(bufnr, key, text)
	if not text or text == "" then
		return
	end
	M.state.streamed[bufnr] = M.state.streamed[bufnr] or {}
	M.state.streamed[bufnr][key] = (M.state.streamed[bufnr][key] or "") .. text
	M.append_to_assistant(bufnr, text)

	local thinking = M.state.thinking[bufnr] or { chars = 0 }
	thinking.chars = thinking.chars + #text
	M.state.thinking[bufnr] = thinking
end

--- Reasoning finished: make the visible text match the authoritative full
--- reasoning text (usually just topping up the last delta).
local function finish_thinking(bufnr, key, full)
	if not full or full == "" then
		return
	end
	M.state.streamed[bufnr] = M.state.streamed[bufnr] or {}
	local acc = M.state.streamed[bufnr][key] or ""
	M.state.streamed[bufnr][key] = full

	local thinking = M.state.thinking[bufnr] or { chars = 0 }
	M.state.thinking[bufnr] = thinking

	if acc == full then
		return
	end
	if acc ~= "" and full:sub(1, #acc) == acc then
		local rest = full:sub(#acc + 1)
		M.append_to_assistant(bufnr, rest)
		thinking.chars = thinking.chars + #rest
		return
	end
	if #acc > 0 then
		M.trim_assistant_tail(bufnr, #acc)
		thinking.chars = math.max(0, thinking.chars - #acc)
	end
	M.append_to_assistant(bufnr, full)
	thinking.chars = thinking.chars + #full
end

function M.auto_scroll(bufnr)
	local info = get_buffer().bufs[bufnr]
	if not info or not info.win_id or not vim.api.nvim_win_is_valid(info.win_id) then
		return
	end
	local cursor = vim.api.nvim_win_get_cursor(info.win_id)
	local lc = vim.api.nvim_buf_line_count(bufnr)
	if cursor[1] >= lc - 2 then
		vim.api.nvim_win_set_cursor(info.win_id, { lc, 0 })
	end
end

function M.subscribe(bufnr)
	if M.state.subscribed[bufnr] then
		return
	end
	M.state.subscribed[bufnr] = true

	local stream = get_stream()
	local buffer = get_buffer()

	local function on(event, handler)
		stream.subscribe(event, function(data)
			local p = payload(data)
			if not matches(bufnr, p) then
				return
			end
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(bufnr) then
					handler(p)
				end
			end)
		end)
	end

	local function text_key(p)
		return tostring(p.assistantMessageID) .. ":" .. tostring(p.ordinal)
	end

	local function reasoning_key(p)
		return "reasoning:" .. tostring(p.assistantMessageID) .. ":" .. tostring(p.ordinal)
	end

	on("session.reasoning.started", function()
		M.state.reasoning_done[bufnr] = nil
		buffer.ensure_section(bufnr, "Assistant")
		local added = ensure_body_break(bufnr)
		if added > 0 then
			local thinking = M.state.thinking[bufnr] or { chars = 0 }
			thinking.chars = thinking.chars + added
			M.state.thinking[bufnr] = thinking
		end
		M.auto_scroll(bufnr)
	end)

	on("session.reasoning.delta", function(p)
		if M.state.reasoning_done[bufnr] then
			return
		end
		buffer.ensure_section(bufnr, "Assistant")
		append_thinking(bufnr, reasoning_key(p), p.delta)
		M.auto_scroll(bufnr)
	end)

	on("session.reasoning.ended", function(p)
		-- `reasoning.ended` can arrive after the answer has started streaming.
		if M.state.reasoning_done[bufnr] then
			return
		end
		buffer.ensure_section(bufnr, "Assistant")
		finish_thinking(bufnr, reasoning_key(p), p.text)
		M.auto_scroll(bufnr)
	end)

	on("session.text.started", function()
		-- The real answer is starting: drop the streamed reasoning text.
		M.state.reasoning_done[bufnr] = true
		M.clear_thinking(bufnr)
		buffer.ensure_section(bufnr, "Assistant")
		ensure_body_break(bufnr)
		M.auto_scroll(bufnr)
	end)

	on("session.text.delta", function(p)
		M.state.reasoning_done[bufnr] = true
		M.clear_thinking(bufnr)
		buffer.ensure_section(bufnr, "Assistant")
		append_streamed(bufnr, text_key(p), p.delta)
		M.auto_scroll(bufnr)
	end)

	on("session.text.ended", function(p)
		M.state.reasoning_done[bufnr] = true
		M.clear_thinking(bufnr)
		buffer.ensure_section(bufnr, "Assistant")
		finish_streamed(bufnr, text_key(p), p.text)
		M.auto_scroll(bufnr)
	end)

	for _, event in ipairs({
		"session.execution.succeeded",
		"session.execution.failed",
		"session.execution.interrupted",
	}) do
		on(event, function(p)
			M.state.streaming[current_session(bufnr)] = nil
			M.clear_thinking(bufnr)
			M.state.reasoning_done[bufnr] = nil
			vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
			buffer.ensure_section(bufnr, "User")
			M.auto_scroll(bufnr)
			if event == "session.execution.failed" and p.error then
				vim.notify("OpenCode error: " .. vim.inspect(p.error), vim.log.levels.ERROR)
			end
		end)
	end

	on("permission.asked", function()
		vim.notify("OpenCode is waiting for permission", vim.log.levels.WARN)
	end)
end

return M

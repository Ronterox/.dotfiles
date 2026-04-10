local M = {}

M.state = { streaming = {} }

local function get_buffer() return require("opencode-mm.buffer") end
local function get_session() return require("opencode-mm.session") end
local function get_stream() return require("opencode-mm.stream") end
local function get_api() return require("opencode-mm.api") end
local function get_config() return require("opencode-mm.config") end

function M.load(bufnr, session_id, callback)
	local session, buffer = get_session(), get_buffer()

	session.get(session_id, function(err, res)
		if err then
			vim.notify("Failed to load session: " .. vim.inspect(err), vim.log.levels.ERROR)
			return callback and callback(err)
		end
		local info = res.body

		session.get_messages(session_id, function(m_err, m_res)
			if m_err then
				vim.notify("Failed to load messages: " .. vim.inspect(m_err), vim.log.levels.ERROR)
				return callback and callback(m_err)
			end

			vim.schedule(function()
				local cfg = get_config().get()
				local defs = cfg and cfg.defaults or {}
				buffer.render_frontmatter(bufnr, {
					model = defs.model or "",
					system = defs.system or "",
					session = session_id,
				})
				buffer.render_messages(bufnr, (m_res and m_res.body) or {})
				buffer.set_session_id(bufnr, session_id)
				local lc = vim.api.nvim_buf_line_count(bufnr)
				vim.api.nvim_buf_set_lines(bufnr, lc, lc, false, { "", "### User", "" })

				local stream = get_stream()
				if not stream.is_connected() then
					local api = get_api()
					api.setup(get_config().get())
					stream.connect(api, function() M._subscribe_events(bufnr) end)
				else
					M._subscribe_events(bufnr)
				end
				if callback then callback(nil, info) end
			end)
		end)
	end)
end

function M.submit(bufnr)
	local buffer, session = get_buffer(), get_session()
	local prompt = buffer.get_pending_prompt(bufnr)
	if prompt == "" then
		vim.notify("No prompt to send", vim.log.levels.WARN)
		return
	end

	local meta = buffer.parse_frontmatter(bufnr)
	if meta.session == "" then
		session.create({}, function(err, res)
			if err then
				vim.notify("Failed to create session: " .. vim.inspect(err), vim.log.levels.ERROR)
				return
			end
			if not res or not res.body or not res.body.id then
				vim.notify("Unexpected session response: " .. vim.inspect(res), vim.log.levels.ERROR)
				return
			end
			vim.schedule(function()
				buffer.set_session_id(bufnr, res.body.id)
				buffer.render_frontmatter(bufnr, { model = meta.model, system = meta.system, session = res.body.id })
				M.submit(bufnr)
			end)
		end)
		return
	end

	local parts = { { type = "text", text = prompt } }
	local opts = {}
	local cfg = get_config().get()
	local defaults = cfg and cfg.defaults or {}
	if meta.model and meta.model ~= "" then
		local provider, model = meta.model:match("([^/]+)/(.+)")
		if provider and model then opts.model = { providerID = provider, modelID = model } end
	elseif defaults.model and defaults.model ~= "" then
		local provider, model = defaults.model:match("([^/]+)/(.+)")
		if provider and model then opts.model = { providerID = provider, modelID = model } end
	end
	if meta.system and meta.system ~= "" then
		opts.system = meta.system
	elseif defaults.system and defaults.system ~= "" then
		opts.system = defaults.system
	end

	M.state.streaming[meta.session] = true
	local lc = vim.api.nvim_buf_line_count(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, lc, lc, false, { "", "### Assistant", "" })

	session.send_message(meta.session, parts, opts, function(err)
		if err then
			vim.schedule(function()
				vim.notify("Failed to send: " .. vim.inspect(err), vim.log.levels.ERROR)
				M.state.streaming[meta.session] = nil
			end)
		end
	end)
end

function M.abort(bufnr)
	local buffer = get_buffer()
	local meta = buffer.parse_frontmatter(bufnr)
	if meta.session == "" then return end
	get_session().abort(meta.session, function(err)
		if err then vim.notify("Abort failed: " .. vim.inspect(err), vim.log.levels.ERROR) end
		M.state.streaming[meta.session] = nil
		vim.schedule(function() vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr }) end)
	end)
end

function M._subscribe_events(bufnr)
	local stream, buffer = get_stream(), get_buffer()

	stream.subscribe("message.part.delta", function(data)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then return end
			local props = data and data.properties or data or {}
			if props.field == "text" and props.delta then
				M._append_to_assistant_section(bufnr, props.delta)
			end
			M._auto_scroll(bufnr)
		end)
	end)

	stream.subscribe("message.part.updated", function(data)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then return end
			local props = data and data.properties or data or {}
			local part = props.part
			if part and part.type == "text" and part.text then
				M._update_assistant_section(bufnr, part.text)
			end
			M._auto_scroll(bufnr)
		end)
	end)

	stream.subscribe("message.updated", function(data)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then return end
			local props = data and data.properties or data or {}
			local info = props.info
			if info and info.finish == "stop" and info.role == "assistant" then
				M.state.streaming[info.sessionID] = nil
				local lc = vim.api.nvim_buf_line_count(bufnr)
				vim.api.nvim_buf_set_lines(bufnr, lc, lc, false, { "", "### User", "" })
			end
			M._auto_scroll(bufnr)
		end)
	end)

	stream.subscribe("session.turn.close", function(data)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then return end
			local props = data and data.properties or data or {}
			M.state.streaming[props.sessionID] = nil
			local lc = vim.api.nvim_buf_line_count(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, lc, lc, false, { "", "### User", "" })
		end)
	end)

	stream.subscribe("session.error", function(data)
		vim.schedule(function()
			local props = data and data.properties or data or {}
			vim.notify("OpenCode error: " .. vim.inspect(props.error), vim.log.levels.ERROR)
			local meta = buffer.parse_frontmatter(bufnr)
			if meta.session then
				M.state.streaming[meta.session] = nil
			end
			vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
		end)
	end)
end

function M._update_assistant_section(bufnr, text)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local start = nil
	for i = #lines, 1, -1 do
		if lines[i]:match("^### [Aa]ssistant") then start = i break end
	end
	if not start then return end
	vim.api.nvim_buf_set_lines(bufnr, start, -1, false, vim.split(text, "\n"))
end

function M._append_to_assistant_section(bufnr, text)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local start = nil
	for i = #lines, 1, -1 do
		if lines[i]:match("^### [Aa]ssistant") then start = i break end
	end
	if not start then return end
	local existing_lines = {}
	for i = start, #lines do
		table.insert(existing_lines, lines[i])
	end
	local updated = table.concat(existing_lines, "\n") .. text
	vim.api.nvim_buf_set_lines(bufnr, start - 1, -1, false, vim.split(updated, "\n"))
end

function M._auto_scroll(bufnr)
	local info = get_buffer().bufs[bufnr]
	if not info or not info.win_id or not vim.api.nvim_win_is_valid(info.win_id) then return end
	local cursor = vim.api.nvim_win_get_cursor(info.win_id)
	local lc = vim.api.nvim_buf_line_count(bufnr)
	if cursor[1] >= lc - 2 then vim.api.nvim_win_set_cursor(info.win_id, { lc, 0 }) end
end

return M

local M = {}

local events = require("opencode-mm.events")

--- Shared streaming state (kept here for backwards compatibility).
M.state = events.state

local function get_buffer()
	return require("opencode-mm.buffer")
end
local function get_session()
	return require("opencode-mm.session")
end
local function get_stream()
	return require("opencode-mm.stream")
end
local function get_api()
	return require("opencode-mm.api")
end
local function get_config()
	return require("opencode-mm.config")
end

local function list(value)
	return type(value) == "table" and value or {}
end

local function record(value)
	return type(value) == "table" and value or {}
end

local function model_ref(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	local provider, id = value:match("([^/]+)/(.+)")
	if not provider or not id then
		return nil
	end
	return { providerID = provider, id = id }
end

local function model_ref_with_variant(value, variant)
	local ref = model_ref(value)
	if ref and variant and variant ~= "" then
		ref.variant = variant
	end
	return ref
end

local function model_string(model)
	if type(model) == "table" and model.providerID and model.id then
		return model.providerID .. "/" .. model.id
	end
	return nil
end

local function connect_stream(bufnr)
	local stream = get_stream()
	if not stream.is_connected() then
		get_api().setup(get_config().get())
		stream.connect(get_api(), function()
			M._subscribe_events(bufnr)
		end)
	else
		M._subscribe_events(bufnr)
	end
end

function M.load(bufnr, session_id, callback)
	local session, buffer = get_session(), get_buffer()

	session.get(session_id, function(err, res)
		if err then
			vim.notify("Failed to load session: " .. vim.inspect(err), vim.log.levels.ERROR)
			return callback and callback(err)
		end
		local info = record(res and res.body and res.body.data)

		session.get_messages(session_id, function(m_err, m_res)
			if m_err then
				vim.notify("Failed to load messages: " .. vim.inspect(m_err), vim.log.levels.ERROR)
				return callback and callback(m_err)
			end

			vim.schedule(function()
				local defaults = get_config().get().defaults or {}
				local model_info = type(info.model) == "table" and info.model or {}
				buffer.render_frontmatter(bufnr, {
					model = model_string(info.model) or defaults.model or "",
					variant = model_info.variant or "",
					system = defaults.system or "",
					session = session_id,
				})
				buffer.render_messages(bufnr, list(m_res and m_res.body and m_res.body.data))
				buffer.set_session_id(bufnr, session_id)
				events.state.streamed[bufnr] = {}
				events.state.thinking[bufnr] = nil
				events.state.reasoning_done[bufnr] = nil
				buffer.ensure_section(bufnr, "User")
				connect_stream(bufnr)
				if callback then
					callback(nil, info)
				end
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
	local defaults = get_config().get().defaults or {}

	local function send(sid)
		local model = model_ref_with_variant(meta.model, meta.variant)
			or model_ref_with_variant(defaults.model, defaults.variant)

		local function prompt_now()
			events.state.streaming[sid] = true
			events.state.streamed[bufnr] = {}
			events.state.thinking[bufnr] = nil
			events.state.reasoning_done[bufnr] = nil
			buffer.ensure_section(bufnr, "Assistant")
			session.send_message(sid, prompt, {}, function(err)
				if err then
					vim.schedule(function()
						vim.notify("Failed to send: " .. vim.inspect(err), vim.log.levels.ERROR)
						events.state.streaming[sid] = nil
					end)
				end
			end)
		end

		if model then
			session.set_model(sid, model, function(err)
				if err then
					vim.schedule(function()
						vim.notify("Failed to switch model: " .. vim.inspect(err), vim.log.levels.WARN)
					end)
				end
				vim.schedule(prompt_now)
			end)
		else
			prompt_now()
		end
	end

	if meta.session == "" then
		session.create({}, function(err, res)
			if err then
				vim.notify("Failed to create session: " .. vim.inspect(err), vim.log.levels.ERROR)
				return
			end
			local data = record(res and res.body and res.body.data)
			if not data.id then
				vim.notify("Unexpected session response: " .. vim.inspect(res), vim.log.levels.ERROR)
				return
			end
			vim.schedule(function()
				buffer.set_session_id(bufnr, data.id)
				buffer.render_frontmatter(bufnr, {
					model = (meta.model ~= "" and meta.model) or model_string(data.model) or defaults.model or "",
					variant = meta.variant or "",
					system = meta.system,
					session = data.id,
				})
				send(data.id)
			end)
		end)
		return
	end

	send(meta.session)
end

function M.abort(bufnr)
	local meta = get_buffer().parse_frontmatter(bufnr)
	if meta.session == "" then
		return
	end
	if not get_stream().is_connected() then
		get_api().setup(get_config().get())
	end
	get_session().abort(meta.session, function(err)
		if err then
			vim.notify("Abort failed: " .. vim.inspect(err), vim.log.levels.ERROR)
		end
		events.state.streaming[meta.session] = nil
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
			end
		end)
	end)
end

function M._subscribe_events(bufnr)
	events.subscribe(bufnr)
end

return M

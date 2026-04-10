--- Session CRUD operations for opencode serve API
local M = {}

M._api = nil

function M.setup(api_client)
	M._api = api_client
end

function M.list(cb)
	M._api.get("/session", cb)
end

function M.create(opts, cb)
	M._api.post("/session", opts, cb)
end

function M.get(session_id, cb)
	M._api.get("/session/" .. session_id, cb)
end

function M.delete(session_id, cb)
	M._api.delete("/session/" .. session_id, cb)
end

function M.get_messages(session_id, cb)
	M._api.get("/session/" .. session_id .. "/message", cb)
end

function M.get_message(session_id, message_id, cb)
	M._api.get("/session/" .. session_id .. "/message/" .. message_id, cb)
end

--- Send message asynchronously (fire-and-forget)
function M.send_message(session_id, parts, opts, callback)
	local body = { parts = parts }
	if opts then
		if opts.model then
			body.model = opts.model
		end
		if opts.system then
			body.system = opts.system
		end
	end
	M._api.post("/session/" .. session_id .. "/prompt_async", body, callback)
end

function M.send_message_sync(session_id, parts, opts, callback)
	local body = { parts = parts }
	if opts then
		if opts.model then
			body.model = opts.model
		end
		if opts.system then
			body.system = opts.system
		end
	end
	M._api.post("/session/" .. session_id .. "/message", body, callback)
end

function M.update_part(session_id, message_id, part_id, content, cb)
	M._api.patch(
		"/session/"
			.. session_id
			.. "/message/"
			.. message_id
			.. "/part/"
			.. part_id,
		{ type = "text", text = content },
		cb
	)
end

function M.delete_message(session_id, message_id, cb)
	M._api.delete("/session/" .. session_id .. "/message/" .. message_id, cb)
end

function M.abort(session_id, cb)
	M._api.post("/session/" .. session_id .. "/abort", {}, cb)
end

function M.get_providers(cb)
	M._api.get("/config/providers", cb)
end

function M.get_config(cb)
	M._api.get("/config", cb)
end

function M.fork(session_id, opts, cb)
	M._api.post("/session/" .. session_id .. "/fork", opts or {}, cb)
end

function M.share(session_id, cb)
	M._api.post("/session/" .. session_id .. "/share", {}, cb)
end

return M

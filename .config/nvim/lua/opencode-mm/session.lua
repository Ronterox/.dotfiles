--- Session operations for the OpenCode v2 API (`/api` prefix).
local M = {}

M._api = nil

local API = "/api"
local MESSAGE_PAGE_SIZE = 200
local MAX_MESSAGE_PAGES = 100

local function list(value)
	return type(value) == "table" and value or {}
end

function M.setup(api_client)
	M._api = api_client
end

--- List sessions, newest first.
function M.list(cb)
	M._api.get(API .. "/session?limit=50&order=desc", cb)
end

--- Create a session, defaulting its location to the current directory.
function M.create(opts, cb)
	local body = vim.deepcopy(opts or {})
	if not body.location then
		body.location = { directory = vim.fn.getcwd() }
	end
	M._api.post(API .. "/session", body, cb)
end

function M.get(session_id, cb)
	M._api.get(API .. "/session/" .. session_id, cb)
end

function M.delete(session_id, cb)
	M._api.delete(API .. "/session/" .. session_id, cb)
end

--- Fetch every message in a session, following cursor pagination.
--- @param session_id string
--- @param cb fun(err, res)
function M.get_messages(session_id, cb)
	local messages = {}

	local function fetch(cursor, page)
		local path = API .. "/session/" .. session_id .. "/message?limit=" .. MESSAGE_PAGE_SIZE
		if cursor then
			path = path .. "&cursor=" .. vim.uri_encode(cursor)
		else
			path = path .. "&order=asc"
		end

		M._api.get(path, function(err, res)
			if err then
				return cb(err, nil)
			end

			local body = (res and res.body) or {}
			for _, message in ipairs(list(body.data)) do
				table.insert(messages, message)
			end

			local next_cursor = type(body.cursor) == "table" and body.cursor.next or nil
			if type(next_cursor) ~= "string" then
				next_cursor = nil
			end
			if next_cursor and page < MAX_MESSAGE_PAGES then
				return fetch(next_cursor, page + 1)
			end

			cb(nil, { status = 200, body = { data = messages } })
		end)
	end

	fetch(nil, 1)
end

function M.get_message(session_id, message_id, cb)
	M._api.get(API .. "/session/" .. session_id .. "/message/" .. message_id, cb)
end

--- Send a prompt. The v2 endpoint takes plain text instead of message parts.
--- A table of `{ type = "text", text = ... }` parts is also accepted for
--- backwards compatibility.
function M.send_message(session_id, prompt, opts, callback)
	if type(prompt) == "table" then
		local texts = {}
		for _, part in ipairs(prompt) do
			if part.type == "text" then
				table.insert(texts, part.text or "")
			end
		end
		prompt = table.concat(texts, "\n")
	end

	local body = { text = prompt or "" }
	if opts then
		if opts.metadata then
			body.metadata = opts.metadata
		end
		if opts.resume ~= nil then
			body.resume = opts.resume
		end
	end

	M._api.post(API .. "/session/" .. session_id .. "/prompt", body, callback)
end

--- Switch the model used by subsequent turns.
function M.set_model(session_id, model, cb)
	M._api.post(API .. "/session/" .. session_id .. "/model", { model = model }, cb)
end

function M.abort(session_id, cb)
	M._api.post(API .. "/session/" .. session_id .. "/interrupt", {}, cb)
end

--- List chat models (v2 `/api/model`).
function M.get_models(cb)
	M._api.get(API .. "/model", cb)
end

--- List providers, kept for compatibility.
function M.get_providers(cb)
	M._api.get(API .. "/provider", cb)
end

function M.get_config(cb)
	M._api.get(API .. "/config", cb)
end

function M.fork(session_id, opts, cb)
	M._api.post(API .. "/session/" .. session_id .. "/fork", opts or {}, cb)
end

return M

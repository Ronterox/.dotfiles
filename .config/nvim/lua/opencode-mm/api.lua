--- HTTP/SSE client for the OpenCode v2 server.
---
--- The URL and password come from the running background service (see
--- `service.lua`); an explicit `serve.url`/`serve.port` still overrides it.
local M = {}

M._config = {}

local HTTP_MARKER = "\n__OPENCODE_HTTP__"

function M.setup(config)
	M._config = config or {}
end

local function service()
	return require("opencode-mm.service")
end

local function serve_config()
	return M._config.serve or {}
end

--- Resolve the current service descriptor.
--- @return table|nil info
function M.resolve()
	local c = serve_config()
	local info = service().discover(c)
	if not info then
		return nil
	end
	info.url = info.url:gsub("/+$", "")
	return info
end

function M._base_url()
	local info = M.resolve()
	return info and info.url or nil
end

local function auth_args(info)
	local c = serve_config()
	local password = c.password or (info and info.password)
	if not password then
		return {}
	end
	-- The v2 server always uses the `opencode` Basic-auth user.
	return { "-u", "opencode:" .. password }
end

local function decode_error(payload)
	local ok, decoded = pcall(vim.json.decode, payload)
	if ok and type(decoded) == "table" and decoded.message then
		return decoded.message
	end
	return payload
end

--- Perform an HTTP request.
--- @param method string
--- @param path string
--- @param body table|nil
--- @param callback fun(err, res)
function M.request(method, path, body, callback)
	local info = M.resolve()
	if not info then
		if callback then
			callback("opencode background service not found (run `opencode service start`)", nil)
		end
		return
	end

	local url = info.url .. path
	local cmd = { "curl", "-sS", "-X", method, url, "-w", HTTP_MARKER .. "%{http_code}" }
	vim.list_extend(cmd, auth_args(info))
	if body and next(body) ~= nil then
		vim.list_extend(cmd, { "-H", "Content-Type: application/json" })
		vim.list_extend(cmd, { "-d", vim.json.encode(body) })
	end

	vim.system(cmd, { text = true }, function(out)
		vim.schedule(function()
			if out.code ~= 0 then
				if callback then
					callback("curl error: " .. (out.stderr or "unknown"), nil)
				end
				return
			end

			local stdout = out.stdout or ""
			local payload, status = stdout:match("^(.-)" .. HTTP_MARKER .. "(%d+)%s*$")
			if not payload then
				payload, status = stdout, "0"
			end
			status = tonumber(status) or 0

			if status < 200 or status >= 300 then
				if callback then
					callback({ status = status, message = decode_error(payload) }, nil)
				end
				return
			end

			if payload == "" then
				if callback then
					callback(nil, { status = status, body = nil })
				end
				return
			end

			local ok, decoded = pcall(vim.json.decode, payload)
			if not ok then
				if callback then
					callback("json decode error: " .. tostring(decoded), { status = status, body = payload })
				end
				return
			end

			if callback then
				callback(nil, { status = status, body = decoded })
			end
		end)
	end)
end

function M.get(path, cb)
	M.request("GET", path, nil, cb)
end

function M.post(path, body, cb)
	M.request("POST", path, body, cb)
end

function M.patch(path, body, cb)
	M.request("PATCH", path, body, cb)
end

function M.delete(path, cb)
	M.request("DELETE", path, nil, cb)
end

function M.health(cb)
	M.get("/api/info", function(err, res)
		if err then
			if cb then
				cb(err, nil)
			end
			return
		end
		if cb then
			cb(nil, res.body)
		end
	end)
end

--- Subscribe to the server-sent event stream.
--- @param path string
--- @param on_event fun(event_type: string, data: table)
--- @param on_error fun(message: string)|nil
function M.sse(path, on_event, on_error)
	local info = M.resolve()
	if not info then
		if on_error then
			on_error("opencode background service not found")
		end
		return nil
	end

	local url = info.url .. path
	local cmd = { "curl", "-sS", "-N", url, "-H", "Accept: text/event-stream" }
	vim.list_extend(cmd, auth_args(info))

	local buf = ""
	local proc = vim.system(cmd, {
		text = true,
		stdout = function(_, data)
			if not data then
				return
			end
			buf = buf .. data
			while true do
				local chunk, rest = buf:match("^(.-)\n\n(.*)$")
				if not chunk then
					break
				end
				buf = rest

				local event_type, event_data
				for line in chunk:gmatch("[^\n]+") do
					if line:match("^event:") then
						event_type = vim.trim(line:sub(7))
					elseif line:match("^data:") then
						local raw = vim.trim(line:sub(6))
						local ok, decoded = pcall(vim.json.decode, raw)
						event_data = ok and decoded or raw
					end
				end

				if not event_type and type(event_data) == "table" and event_data.type then
					event_type = event_data.type
				end
				if event_type then
					vim.schedule(function()
						on_event(event_type, event_data)
					end)
				end
			end
		end,
	}, function(out)
		if out.code ~= 0 then
			vim.schedule(function()
				if on_error then
					on_error("sse disconnected: " .. (out.stderr or ""))
				end
			end)
		end
	end)

	return {
		stop = function()
			pcall(function()
				proc:kill(15)
			end)
		end,
	}
end

return M

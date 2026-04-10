local M = {}

M._config = {}

function M.setup(config)
	M._config = config or {}
end

function M._base_url()
	local c = M._config.serve or {}
	return string.format("http://%s:%d", c.host or "127.0.0.1", c.port or 11634)
end

function M._auth_args()
	local pw = M._config.serve and M._config.serve.password
	if not pw then return {} end
	return { "-u", (M._config.serve.username or "opencode") .. ":" .. pw }
end

function M.request(method, path, body, callback)
	local url = M._base_url() .. path
	local cmd = { "curl", "-s", "-X", method, url }
	vim.list_extend(cmd, M._auth_args())
	if body and next(body) ~= nil then
		vim.list_extend(cmd, { "-H", "Content-Type: application/json" })
		vim.list_extend(cmd, { "-d", vim.json.encode(body) })
	end

	vim.system(cmd, { text = true }, function(out)
		vim.schedule(function()
			if out.code ~= 0 then
				if callback then callback("curl error: " .. (out.stderr or "unknown"), nil) end
				return
			end
			local stdout = out.stdout or ""
			if stdout == "" then
				if callback then callback(nil, { status = 204, body = nil }) end
				return
			end
			local ok, decoded = pcall(vim.json.decode, stdout)
			if not ok then
				if callback then callback("json decode error: " .. decoded, { status = 0, body = stdout }) end
				return
			end
			if callback then callback(nil, { status = 200, body = decoded }) end
		end)
	end)
end

function M.get(path, cb) M.request("GET", path, nil, cb) end
function M.post(path, body, cb) M.request("POST", path, body, cb) end
function M.patch(path, body, cb) M.request("PATCH", path, body, cb) end
function M.delete(path, cb) M.request("DELETE", path, nil, cb) end

function M.health(cb)
	M.get("/global/health", function(err, res)
		if err then
			if cb then cb(err, nil) end
			return
		end
		if cb then cb(nil, res.body) end
	end)
end

function M.sse(path, on_event, on_error)
	local url = M._base_url() .. path
	local cmd = { "curl", "-s", "-N", url }
	vim.list_extend(cmd, M._auth_args())

	local buf = ""
	local proc = vim.system(cmd, {
		text = true,
		stdout = function(_, data)
			if not data then return end
			buf = buf .. data
			for chunk in buf:gmatch("(.-)\n\n") do
				local event_type, event_data
				for line in chunk:gmatch("[^\n]+") do
					if line:match("^event:") then
						event_type = line:sub(8):match("^%s*(.-)%s*$")
					elseif line:match("^data:") then
						local raw = line:sub(7)
						local ok, decoded = pcall(vim.json.decode, raw)
						event_data = ok and decoded or raw
					end
				end
				-- If no explicit event: line, extract type from data payload
				if not event_type and event_data and event_data.type then
					event_type = event_data.type
				end
				if event_type then
					vim.schedule(function() on_event(event_type, event_data) end)
				end
			end
			buf = buf:match(".*\n\n(.+)$") or ""
		end,
	}, function(out)
		if out.code ~= 0 then
			vim.schedule(function()
				if on_error then on_error("sse disconnected: " .. (out.stderr or "")) end
			end)
		end
	end)

	return {
		stop = function()
			if proc and proc:is_closing() == false then
				proc:kill(vim.uv.constants.SIGTERM)
			end
		end,
	}
end

return M

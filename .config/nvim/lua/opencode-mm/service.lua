--- Locates the OpenCode v2 background service.
---
--- OpenCode no longer listens on a fixed port. The background service picks a
--- random port, writes its URL, PID and Basic-auth password to
--- `$XDG_STATE_HOME/opencode/service.json`, and every API call must be
--- authenticated with user `opencode` and that password.
local M = {}

M.state = {
	last_start_attempt = 0,
}

local START_COOLDOWN_MS = 30000

local function state_file(config)
	local c = config or {}
	if c.service_file and c.service_file ~= "" then
		return c.service_file
	end
	local base = vim.env.XDG_STATE_HOME
	if not base or base == "" then
		base = vim.fn.expand("~/.local/state")
	end
	return base .. "/opencode/service.json"
end

local function read_json(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or not lines or #lines == 0 then
		return nil
	end
	local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not decoded_ok or type(decoded) ~= "table" then
		return nil
	end
	return decoded
end

local function pid_alive(pid)
	if type(pid) ~= "number" or pid <= 0 then
		return true -- no PID recorded, trust the URL
	end
	local ok, result = pcall(vim.uv.kill, pid, 0)
	return ok and result == 0
end

--- Read the current service descriptor.
--- @param config table|nil `serve` config section
--- @return table|nil info `{ url, password, pid, version }`
--- @return string|nil error
function M.read(config)
	local info = read_json(state_file(config))
	if not info or type(info.url) ~= "string" or info.url == "" then
		return nil, "opencode service.json not found or invalid"
	end
	if not pid_alive(info.pid) then
		return nil, "opencode service process is not running"
	end
	return info
end

local function opencode_exe()
	local exe = vim.fn.exepath("opencode")
	if type(exe) ~= "string" or exe == "" then
		exe = "opencode"
	end
	return exe
end

--- Start the background service (idempotent) and wait for its state file.
function M.start()
	local now = vim.uv.now()
	if now - M.state.last_start_attempt < START_COOLDOWN_MS then
		return false
	end
	M.state.last_start_attempt = now

	local out = vim.system(
		{ opencode_exe(), "service", "start" },
		{ text = true }
	):wait(15000)

	return out ~= nil and out.code == 0
end

--- Resolve the service URL/password from explicit config, service.json, or a
--- freshly started background service.
--- @param config table|nil `serve` config section
--- @return table|nil info
--- @return string|nil error
function M.discover(config)
	local c = config or {}

	if c.url and c.url ~= "" then
		local info = M.read(c)
		return {
			url = c.url,
			password = c.password or (info and info.password),
			source = "config",
		}
	end

	-- Legacy escape hatch: an explicitly configured host/port targets a
	-- manually started server and bypasses discovery/auto-start.
	if type(c.port) == "number" then
		local info = M.read(c)
		return {
			url = string.format("http://%s:%d", c.host or "127.0.0.1", c.port),
			password = c.password or (info and info.password),
			source = "config-port",
		}
	end

	local info, err = M.read(c)
	if info then
		if c.password then
			info.password = c.password
		end
		return info
	end

	if c.auto_start ~= false then
		M.start()
		info = M.read(c)
		if info then
			if c.password then
				info.password = c.password
			end
			return info
		end
	end

	return nil, err or "opencode background service not found"
end

return M

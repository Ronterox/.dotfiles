--- SSE event stream manager for opencode serve
local M = {}

M.state = {
	handle = nil,
	callbacks = {},
	connected = false,
	reconnect_timer = nil,
	should_connect = false,
	api = nil,
}

local RECONNECT_DELAY = 2000

function M.connect(api_client, on_ready)
	M.state.api = api_client
	M.state.should_connect = true
	M._do_connect(on_ready)
end

function M._do_connect(on_ready)
	if not M.state.should_connect then
		return
	end

	M.state.handle = M.state.api.sse("/event", function(event_type, data)
		M._dispatch(event_type, data)
	end, function(err)
		M.state.connected = false
		if M.state.should_connect then
			M._schedule_reconnect()
		end
	end)

	M.state.connected = true
	if on_ready then
		on_ready()
	end
end

function M._schedule_reconnect()
	if M.state.reconnect_timer then
		return
	end
	M.state.reconnect_timer = vim.defer_fn(function()
		M.state.reconnect_timer = nil
		if M.state.should_connect then
			M._do_connect()
		end
	end, RECONNECT_DELAY)
end

function M.disconnect()
	M.state.should_connect = false
	M.state.connected = false

	if M.state.handle then
		pcall(function()
			M.state.handle:stop()
		end)
		M.state.handle = nil
	end

	M.state.reconnect_timer = nil
	M.state.callbacks = {}
end

function M.subscribe(event_type, callback)
	if not M.state.callbacks[event_type] then
		M.state.callbacks[event_type] = {}
	end
	table.insert(M.state.callbacks[event_type], callback)
end

function M.unsubscribe(event_type)
	M.state.callbacks[event_type] = nil
end

function M._dispatch(event_type, data)
	local handlers = M.state.callbacks[event_type]
	if not handlers then
		return
	end
	for _, cb in ipairs(handlers) do
		cb(data)
	end
end

function M.is_connected()
	return M.state.connected
end

return M

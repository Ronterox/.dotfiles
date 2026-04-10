-- Config module for opencode-mm Neovim plugin
-- Manages default configuration and user overrides with validation

local M = {}

--- Default configuration settings
M.defaults = {
	serve = { host = "127.0.0.1", port = 11634, password = nil },
	defaults = { model = "kilo/kilo-auto/free", system = "You are a helpful assistant." },
	chords = {
		c = "create a ",
		f = "fix the ",
		r = "refactor the ",
		s = "secured focused ",
		o = "optimized ",
		t = "test for ",
		d = "document the ",
		a = "add a ",
		e = "explain the "
	},
	parametric_chords = {
		l = "in no more than $arg lines",
		w = "without exceeding $arg words",
		p = "with priority $arg"
	},
	window = { width = 0.6, height = 0.8, position = "right" },
	submit_on_cr = true,
	mastermind_timeout = 0,
}

--- Current merged configuration
M.config = vim.tbl_deep_extend("force", {}, M.defaults)

--- Setup and validate configuration
-- @param user_opts table User-provided configuration options
M.setup = function(user_opts)
	if not user_opts or type(user_opts) ~= "table" then
		return
	end

	-- Validate port is a number
	if user_opts.serve and type(user_opts.serve.port) ~= "number" then
		user_opts.serve.port = 11634
	end

	-- Validate chords is a table
	if user_opts.chords and type(user_opts.chords) ~= "table" then
		user_opts.chords = {}
	end

	-- Validate window dimensions are numbers 0-1
	if user_opts.window then
		if type(user_opts.window.width) ~= "number" then
			user_opts.window.width = 0.6
		elseif user_opts.window.width < 0 or user_opts.window.width > 1 then
			user_opts.window.width = 0.6
		end

		if type(user_opts.window.height) ~= "number" then
			user_opts.window.height = 0.8
		elseif user_opts.window.height < 0 or user_opts.window.height > 1 then
			user_opts.window.height = 0.8
		end
	end

	-- Merge with defaults
	M.config = vim.tbl_deep_extend("force", M.defaults, user_opts)
end

--- Get current configuration
-- @return table Current merged configuration
M.get = function()
	return M.config
end

return M

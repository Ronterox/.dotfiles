--- OpenCode Mastermind - Neovim plugin for opencode serve
--- Public API entry point
local M = {}

M._initialized = false

function M.setup(opts)
	local config = require("opencode-mm.config")
	config.setup(opts)
	local cfg = config.get()

	require("opencode-mm.chords").setup(cfg)
	require("opencode-mm.api").setup(cfg)

	vim.api.nvim_create_user_command("OpenCode", function(o)
		M._command(o)
	end, {
		nargs = "?",
		complete = function(arg_lead)
			local cmds = { "new", "select", "model" }
			return vim.tbl_filter(function(c)
				return c:find("^" .. arg_lead)
			end, cmds)
		end,
	})

	M._initialized = true
	return M
end

function M.toggle()
	local buffer = require("opencode-mm.buffer")
	for bufnr, info in pairs(buffer.bufs) do
		if info.win_id and vim.api.nvim_win_is_valid(info.win_id) then
			local win_tab = vim.api.nvim_win_get_tabpage(info.win_id)
			if win_tab == vim.api.nvim_get_current_tabpage() then
				buffer.close(bufnr)
				return
			end
		end
	end
	M.open()
end

function M.open(session_id)
	local config = require("opencode-mm.config")
	local buffer = require("opencode-mm.buffer")
	local api = require("opencode-mm.api")
	local session = require("opencode-mm.session")
	local stream = require("opencode-mm.stream")
	local conversation = require("opencode-mm.conversation")

	session.setup(api)
	local cfg = config.get()

	local function setup_buf(bufnr)
		buffer.setup_keymaps(bufnr, function()
			conversation.submit(bufnr)
		end, function()
			conversation.abort(bufnr)
		end)
	end

	if session_id then
		local bufnr = buffer.create(session_id)
		buffer.open(bufnr, cfg)
		conversation.load(bufnr, session_id, function()
			setup_buf(bufnr)
		end)
	else
		session.create(nil, function(err, res)
			if err then
				vim.notify("Failed to create session: " .. vim.inspect(err), vim.log.levels.ERROR)
				return
			end
			if not res or not res.body or not res.body.id then
				vim.notify("Unexpected session response: " .. vim.inspect(res), vim.log.levels.ERROR)
				return
			end
			vim.schedule(function()
				local sid = res.body.id
				local bufnr = buffer.create(sid)
				buffer.open(bufnr, cfg)
				buffer.render_frontmatter(bufnr, { model = cfg.defaults and cfg.defaults.model or "", system = cfg.defaults and cfg.defaults.system or "", session = sid })
				vim.api.nvim_buf_set_lines(bufnr, 6, -1, false, { "### User", "" })
				setup_buf(bufnr)
				if not stream.is_connected() then
					stream.connect(api, function() end)
				end
			end)
		end)
	end
end

function M.close()
	local buffer = require("opencode-mm.buffer")
	local bufnr = vim.api.nvim_get_current_buf()
	if buffer.is_opencode_buf(bufnr) then
		buffer.close(bufnr)
	end
end

function M.new_session()
	M.open()
end

function M.select_session()
	local session = require("opencode-mm.session")
	session.setup(require("opencode-mm.api"))
	session.list(function(err, res)
		if err then
			vim.notify("Failed to list sessions: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end
		vim.schedule(function()
			local sessions = (res and res.body) or {}
			local items = {}
			for _, s in ipairs(sessions) do
				table.insert(items, (s.title or "Untitled") .. " (" .. s.id:sub(1, 8) .. ")")
			end
			vim.ui.select(items, { prompt = "Select session:" }, function(_, idx)
				if idx and sessions[idx] then
					M.open(sessions[idx].id)
				end
			end)
		end)
	end)
end

function M.select_model()
	local session = require("opencode-mm.session")
	session.setup(require("opencode-mm.api"))
	local bufnr = vim.api.nvim_get_current_buf()
	local buffer = require("opencode-mm.buffer")
	if not buffer.is_opencode_buf(bufnr) then
		return
	end

	session.get_providers(function(err, res)
		if err then
			vim.notify("Failed to get providers: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end
		vim.schedule(function()
			local providers = (res and res.body) or {}
			local models = {}
			for _, p in ipairs(providers) do
				if p.models then
					for _, m in ipairs(p.models) do
						table.insert(models, {
							display = (p.id or "?") .. "/" .. (m.id or "?"),
							providerID = p.id,
							modelID = m.id,
						})
					end
				end
			end
			vim.ui.select(
				vim.tbl_map(function(m)
					return m.display
				end, models),
				{ prompt = "Select model:" },
				function(_, idx)
					if idx and models[idx] then
						local m = models[idx]
						local meta = buffer.parse_frontmatter(bufnr)
						meta.model = m.providerID .. "/" .. m.modelID
						buffer.render_frontmatter(bufnr, meta)
					end
				end
			)
		end)
	end)
end

function M._command(opts)
	local arg = vim.trim(opts.args or "")
	if arg == "" then
		return M.toggle()
	end
	if arg == "new" then
		return M.new_session()
	end
	if arg == "select" then
		return M.select_session()
	end
	if arg == "model" then
		return M.select_model()
	end
	M.open(arg)
end

return M

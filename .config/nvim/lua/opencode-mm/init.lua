--- OpenCode Mastermind - Neovim plugin for the OpenCode v2 server
--- Public API entry point
local M = {}

M._initialized = false

local function model_string(model)
	if type(model) == "table" and model.providerID and model.id then
		return model.providerID .. "/" .. model.id
	end
	return nil
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

local function list(value)
	return type(value) == "table" and value or {}
end

local function record(value)
	return type(value) == "table" and value or {}
end

local function err_text(err)
	if type(err) == "table" then
		if err.message and err.message ~= "" then
			return tostring(err.message)
		end
		if err.status then
			return "HTTP " .. tostring(err.status)
		end
	end
	return tostring(err)
end

function M.setup(opts)
	local config = require("opencode-mm.config")
	config.setup(opts)
	local cfg = config.get()

	require("opencode-mm.chords").setup(cfg)
	require("opencode-mm.api").setup(cfg)

	-- Global <leader><leader> mapping to activate mastermind in ANY buffer
	-- This allows offline chorded text expansion without requiring the opencode server
	vim.keymap.set("n", "<leader><leader>", function()
		local bufnr = vim.api.nvim_get_current_buf()
		require("opencode-mm.mastermind").enter(bufnr)
	end, { noremap = true, silent = true })

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
	local config = require("opencode-mm.config")

	for bufnr, info in pairs(buffer.bufs) do
		if info.win_id and vim.api.nvim_win_is_valid(info.win_id) then
			local win_tab = vim.api.nvim_win_get_tabpage(info.win_id)
			if win_tab == vim.api.nvim_get_current_tabpage() then
				vim.api.nvim_win_close(info.win_id, true)
				buffer.bufs[bufnr].win_id = nil
				return
			end
		end
	end

	local cfg = config.get()
	for bufnr, info in pairs(buffer.bufs) do
		buffer.open(bufnr, cfg)
		return
	end

	M.open()
end

function M.open(session_id, on_ready)
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
		if on_ready then
			on_ready(bufnr)
		end
	end

	if session_id then
		local bufnr = buffer.create(session_id)
		buffer.open(bufnr, cfg)
		conversation.load(bufnr, session_id, function()
			setup_buf(bufnr)
		end)
	else
		local create_opts = {}
		local default_model = model_ref(cfg.defaults and cfg.defaults.model)
		if default_model then
			if cfg.defaults.variant and cfg.defaults.variant ~= "" then
				default_model.variant = cfg.defaults.variant
			end
			create_opts.model = default_model
		end
		session.create(create_opts, function(err, res)
			if err then
				vim.notify("Failed to create session: " .. vim.inspect(err), vim.log.levels.ERROR)
				return
			end
			local data = record(res and res.body and res.body.data)
			if not data or not data.id then
				vim.notify("Unexpected session response: " .. vim.inspect(res), vim.log.levels.ERROR)
				return
			end
			vim.schedule(function()
				local sid = data.id
				local bufnr = buffer.create(sid)
				buffer.open(bufnr, cfg)
				buffer.render_frontmatter(bufnr, {
					model = model_string(data.model) or (cfg.defaults and cfg.defaults.model) or "",
					variant = (type(data.model) == "table" and data.model.variant) or "",
					system = (cfg.defaults and cfg.defaults.system) or "",
					session = sid,
				})
				vim.api.nvim_buf_set_lines(bufnr, buffer._find_frontmatter_end(bufnr) + 1, -1, false, { "### User", "" })
				setup_buf(bufnr)
				if not stream.is_connected() then
					stream.connect(api, function()
						conversation._subscribe_events(bufnr)
					end)
				else
					conversation._subscribe_events(bufnr)
				end
			end)
		end)
	end
end

--- Find an existing opencode-mm buffer, preferring the current window, then
--- any window in the current tabpage, then any buffer tracked by the plugin.
local function find_opencode_buffer()
	local buffer = require("opencode-mm.buffer")
	local cur = vim.api.nvim_get_current_buf()
	if buffer.is_opencode_buf(cur) then
		return cur
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local b = vim.api.nvim_win_get_buf(win)
		if buffer.is_opencode_buf(b) then
			return b
		end
	end
	for bufnr in pairs(buffer.bufs) do
		return bufnr
	end
	return nil
end

local function focus_opencode_buffer(bufnr)
	local buffer = require("opencode-mm.buffer")
	local info = buffer.bufs[bufnr]
	local win
	if info and info.win_id and vim.api.nvim_win_is_valid(info.win_id) then
		win = info.win_id
		vim.api.nvim_set_current_win(win)
		if vim.api.nvim_win_get_buf(win) ~= bufnr then
			vim.api.nvim_win_set_buf(win, bufnr)
		end
	else
		win = buffer.open(bufnr, require("opencode-mm.config").get())
	end
	if win and vim.api.nvim_win_is_valid(win) then
		local lc = vim.api.nvim_buf_line_count(bufnr)
		vim.api.nvim_win_set_cursor(win, { math.max(lc, 1), 0 })
	end
end

--- Send the current visual selection to OpenCode as a line-range reference
--- (`@path#start-end`) appended to the pending prompt.
function M.send_selection()
	local mode = vim.fn.mode()
	local start_line, end_line
	if mode == "v" or mode == "V" or mode == "\22" then
		start_line = vim.fn.line("v")
		end_line = vim.fn.line(".")
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	else
		local first = vim.fn.getpos("'<")
		local last = vim.fn.getpos("'>")
		start_line, end_line = first[2], last[2]
	end

	if not start_line or not end_line or start_line < 1 or end_line < 1 then
		vim.notify("opencode-mm: no visual selection", vim.log.levels.WARN)
		return
	end
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("opencode-mm: cannot reference an unnamed buffer", vim.log.levels.WARN)
		return
	end
	local path = vim.fn.fnamemodify(file, ":.")
	local ref = string.format("@%s#%d-%d", path, start_line, end_line)

	local buffer = require("opencode-mm.buffer")
	local bufnr = find_opencode_buffer()
	if not bufnr then
		M.open(nil, function(new_bufnr)
			buffer.append_pending_prompt(new_bufnr, ref)
			focus_opencode_buffer(new_bufnr)
		end)
		return
	end

	buffer.append_pending_prompt(bufnr, ref)
	focus_opencode_buffer(bufnr)
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
			local sessions = list(res and res.body and res.body.data)
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

--- Normalise a `/api/model` entry into the shape used by the picker.
local function normalise_model(m)
	local model_id = m.modelID or m.id
	if not m.providerID or not model_id then
		return nil
	end
	local ctx = type(m.limit) == "table" and m.limit.context or nil
	return {
		providerID = m.providerID,
		modelID = model_id,
		name = m.name or model_id,
		family = m.family or "",
		context = ctx,
		variants = type(m.variants) == "table" and m.variants or {},
	}
end

local function format_context(ctx)
	if type(ctx) ~= "number" then
		return ""
	end
	if ctx >= 1000000 then
		return string.format("%.0fM", ctx / 1000000)
	end
	if ctx >= 1000 then
		return string.format("%.0fK", ctx / 1000)
	end
	return tostring(ctx)
end

local function apply_model(model, variant)
	local ref = {
		providerID = model.providerID,
		id = model.modelID,
	}
	if variant then
		ref.variant = variant
	end
	local label = model.providerID .. "/" .. model.modelID
	if variant then
		label = label .. " [" .. variant .. "]"
	end

	-- Remember the choice for new sessions.
	local cfg_defaults = require("opencode-mm.config").get().defaults
	cfg_defaults.model = model.providerID .. "/" .. model.modelID
	cfg_defaults.variant = variant or ""

	local buffer = require("opencode-mm.buffer")
	local bufnr = vim.api.nvim_get_current_buf()
	if not buffer.is_opencode_buf(bufnr) then
		vim.notify("OpenCode default model: " .. label, vim.log.levels.INFO)
		return
	end

	local meta = buffer.parse_frontmatter(bufnr)
	meta.model = model.providerID .. "/" .. model.modelID
	meta.variant = variant or ""
	buffer.render_frontmatter(bufnr, meta)

	local sid = meta.session
	if not sid or sid == "" then
		vim.notify("OpenCode model: " .. label, vim.log.levels.INFO)
		return
	end

	require("opencode-mm.session").set_model(sid, ref, function(err)
		if err then
			vim.schedule(function()
				vim.notify("Failed to switch model: " .. err_text(err), vim.log.levels.ERROR)
			end)
			return
		end
		vim.schedule(function()
			vim.notify("OpenCode model: " .. label, vim.log.levels.INFO)
		end)
	end)
end

local function choose_variant(model, done)
	if #model.variants == 0 then
		return done(nil)
	end
	local labels = { "default" }
	local values = { nil }
	for _, v in ipairs(model.variants) do
		if type(v) == "table" and v.id then
			table.insert(labels, v.id)
			table.insert(values, v.id)
		end
	end
	if #labels == 1 then
		return done(nil)
	end
	vim.ui.select(labels, { prompt = "Variant for " .. model.name .. ":" }, function(_, idx)
		if not idx then
			return
		end
		done(values[idx])
	end)
end

local function telescope_models(models, current)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local entries = {}
	for _, m in ipairs(models) do
		local is_current = current == m.providerID .. "/" .. m.modelID
		local ctx = format_context(m.context)
		local display = string.format("%s %-18s %s", is_current and "●" or " ", m.providerID, m.name)
		if ctx ~= "" then
			display = display .. "  · " .. ctx
		end
		table.insert(entries, {
			value = m,
			display = display,
			ordinal = string.format("%s %s %s %s", m.providerID, m.modelID, m.name, m.family),
		})
	end

	pickers
		.new({}, {
			prompt_title = "OpenCode models",
			results_title = "models (" .. #models .. ")",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return entry
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if entry and entry.value then
						choose_variant(entry.value, function(variant)
							apply_model(entry.value, variant)
						end)
					end
				end)
				return true
			end,
		})
		:find()
end

local function fallback_models(models, current)
	local labels = {}
	for _, m in ipairs(models) do
		local marker = (current == m.providerID .. "/" .. m.modelID) and "● " or "  "
		table.insert(labels, marker .. m.providerID .. "/" .. m.modelID .. " — " .. m.name)
	end
	vim.ui.select(labels, { prompt = "OpenCode model:" }, function(_, idx)
		if not idx then
			return
		end
		choose_variant(models[idx], function(variant)
			apply_model(models[idx], variant)
		end)
	end)
end

--- Model picker equivalent to the OpenCode TUI model dialog (<leader>cm).
function M.select_model()
	local session = require("opencode-mm.session")
	session.setup(require("opencode-mm.api"))

	local bufnr = vim.api.nvim_get_current_buf()
	local buffer = require("opencode-mm.buffer")
	local current
	if buffer.is_opencode_buf(bufnr) then
		local meta = buffer.parse_frontmatter(bufnr)
		current = (meta.model ~= "" and meta.model) or nil
	else
		local defaults = require("opencode-mm.config").get().defaults or {}
		current = defaults.model
	end

	session.get_models(function(err, res)
		if err then
			vim.notify("Failed to get models: " .. err_text(err), vim.log.levels.ERROR)
			return
		end
		vim.schedule(function()
			local models = {}
			for _, raw in ipairs(list(res and res.body and res.body.data)) do
				if (raw.type == nil or raw.type == "chat") and raw.enabled ~= false then
					local m = normalise_model(raw)
					if m then
						table.insert(models, m)
					end
				end
			end
			table.sort(models, function(a, b)
				if a.providerID == b.providerID then
					return a.name:lower() < b.name:lower()
				end
				return a.providerID < b.providerID
			end)

			if #models == 0 then
				vim.notify("No models available", vim.log.levels.WARN)
				return
			end

			local ok, perr = pcall(function()
				telescope_models(models, current)
			end)
			if not ok then
				if vim.g.opencode_mm_debug then
					vim.notify("opencode-mm: telescope picker failed: " .. tostring(perr), vim.log.levels.WARN)
				end
				fallback_models(models, current)
			end
		end)
	end)
end

--- Return the model currently in use, including any variant suffix.
function M.current_model()
	local buffer = require("opencode-mm.buffer")
	local bufnr = vim.api.nvim_get_current_buf()
	local model, variant
	if buffer.is_opencode_buf(bufnr) then
		local meta = buffer.parse_frontmatter(bufnr)
		model, variant = meta.model, meta.variant
	else
		local defaults = require("opencode-mm.config").get().defaults or {}
		model, variant = defaults.model, defaults.variant
	end
	if not model or model == "" then
		return nil
	end
	if variant and variant ~= "" then
		return model .. " [" .. variant .. "]"
	end
	return model
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

--- Build a `@path#start-end` reference for the current file, using the live
--- visual selection or the last visual marks in this buffer when present.
local function current_reference()
	local bufnr = vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(bufnr)
	if file == "" then
		return nil
	end
	local path = vim.fn.fnamemodify(file, ":.")

	local start_line, end_line
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		start_line = vim.fn.line("v")
		end_line = vim.fn.line(".")
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	else
		-- '< and '> are buffer-local; a bufnum of 0 means "current buffer".
		local first = vim.fn.getpos("'<")
		local last = vim.fn.getpos("'>")
		local same_buffer = (first[1] == 0 or first[1] == bufnr)
			and (last[1] == 0 or last[1] == bufnr)
		if same_buffer and first[2] > 0 and last[2] > 0 then
			start_line = first[2]
			end_line = last[2]
		end
	end

	if start_line and end_line then
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
		return string.format("@%s#%d-%d", path, start_line, end_line)
	end

	return "@" .. path
end

--- Insert text into the pending prompt of the opencode buffer, creating the
--- buffer first when necessary. Calls `after(bufnr)` once the text is in place.
local function with_opencode_buffer(text, after)
	local buffer = require("opencode-mm.buffer")
	local bufnr = find_opencode_buffer()
	if not bufnr then
		M.open(nil, function(new_bufnr)
			buffer.append_pending_prompt(new_bufnr, text)
			focus_opencode_buffer(new_bufnr)
			if after then
				after(new_bufnr)
			end
		end)
		return
	end
	buffer.append_pending_prompt(bufnr, text)
	focus_opencode_buffer(bufnr)
	if after then
		after(bufnr)
	end
end

--- Ask opencode about the current file or visual selection (<leader>ca).
--- Inserts a `@path` reference into the prompt and leaves the cursor there so
--- you can type the question.
function M.ask()
	local ref = current_reference()
	if not ref then
		vim.notify("opencode-mm: cannot reference an unnamed buffer", vim.log.levels.WARN)
		return
	end
	with_opencode_buffer(ref .. ": ", function(bufnr)
		local win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_get_buf(win) == bufnr then
			local lc = vim.api.nvim_buf_line_count(bufnr)
			vim.api.nvim_win_set_cursor(win, { lc, #(vim.api.nvim_buf_get_lines(bufnr, lc - 1, lc, false)[1] or "") })
			vim.cmd("startinsert!")
		end
	end)
end

M._actions = {
	{ name = "Explain", prompt = "Explain " },
	{ name = "Review", prompt = "Review for bugs and edge cases: " },
	{ name = "Fix", prompt = "Fix " },
	{ name = "Refactor", prompt = "Refactor " },
	{ name = "Add docs", prompt = "Add documentation to " },
	{ name = "Write tests", prompt = "Write tests for " },
}

--- Pick an OpenCode action for the current file or selection (<leader>cx),
--- then submit it.
function M.execute()
	local ref = current_reference()
	if not ref then
		vim.notify("opencode-mm: cannot reference an unnamed buffer", vim.log.levels.WARN)
		return
	end

	local names = vim.tbl_map(function(a)
		return a.name
	end, M._actions)

	vim.ui.select(names, { prompt = "OpenCode action:" }, function(_, idx)
		if not idx then
			return
		end
		local text = M._actions[idx].prompt .. ref
		with_opencode_buffer(text, function(bufnr)
			require("opencode-mm.conversation").submit(bufnr)
		end)
	end)
end

-- Keymaps equivalent to the ones the old opencode.nvim plugin provided.
vim.keymap.set({ "n", "x" }, "<leader>ca", function()
	require("opencode-mm").ask()
end, { desc = "Ask OpenCode about this", silent = true })

vim.keymap.set({ "n", "x" }, "<leader>cx", function()
	require("opencode-mm").execute()
end, { desc = "OpenCode action for this", silent = true })

vim.keymap.set("n", "<leader>cm", function()
	require("opencode-mm").select_model()
end, { desc = "OpenCode model picker", silent = true })

return M

return {
	{
		'supermaven-inc/supermaven-nvim',
		config = function()
			require('supermaven-nvim').setup({
				keymaps = {
					accept_suggestion = "<Tab>",
					clear_suggestion = "<C-]>",
					accept_word = "<C-j>",
				},
				color = {
					suggestion = '#8a8a8a',
					cterm = '244',
				},
			})
		end,
	},
	{
		"ai-lsp",
		virtual = true, -- not real repo
		config = function()
			vim.diagnostic.config({
				virtual_text = {
					prefix = '●', -- Or '■', '▎', 'x'
					spacing = 4,
				},
				underline = true, -- This ensures the code itself is underlined
				severity_sort = true,
				signs = true,
			})

			-- For the text at the end of the line
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#ff0000", italic = true })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#ffa500", italic = true })

			-- For the underline under the actual code
			vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#ff0000" })

			-- To make the whole line have a faint red background (Optional)
			vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#330000" })

			---@param bufnr number
			---@param line number
			---@param severity string
			---@param message string
			local function lint_data(bufnr, line, severity, message)
				return {
					bufnr = bufnr,                 -- 0 refers to the current buffer
					lnum = line,                   -- Line number (0-indexed, so 10 is actually line 11)
					col = 0,                       -- Column number (0-indexed)
					end_col = 80,                  -- Highlight first 80
					severity = vim.diagnostic.severity[severity], -- ERROR, WARN, INFO, or HINT
					message = message,
					source = "ai_linter",
				}
			end

			vim.keymap.set('n', '<leader>cl', function()
				local buffer = vim.api.nvim_get_current_buf()
				local filename = vim.api.nvim_buf_get_name(buffer)
				local namespace = vim.api.nvim_create_namespace("ai_linter")

				local prompt = "What is wrong with this file? " .. filename
				-- local prompt = "This is a test send an example output"
				local command = {
					"stdbuf", "-oL",
					"opencode", "run",
					"--agent", "linter",
					"--thinking", prompt
				}

				vim.notify("Saving file! AI lsp linter is cooking...")
				vim.cmd.write()

				local bufnr = vim.api.nvim_create_buf(true, true)
				vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
				vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
				vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })

				vim.api.nvim_buf_set_name(bufnr, "AI Linter " .. bufnr)
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, command)

				vim.diagnostic.reset(namespace, buffer)

				vim.system(command, {
					text = true,
					on_stdout = function(err, data)
						if data then
							vim.schedule(function()
								local lines = vim.split(data, "[\r\n]+")
								if #lines > 0 and lines[1] == "" then table.remove(lines, 1) end

								vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)

								local win = vim.fn.bufwinid(bufnr)
								if win ~= -1 then
									vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(bufnr), 0 })
								end
							end)
						end
					end,
				}, function(out)
					if out.code == 0 then
						vim.schedule(function()
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(out.stdout, "\n"))

							local reversed = out.stdout:reverse()
							local start, finish = reversed:find("%]%s*}.-{%s*%[")

							if not start then
								vim.notify("Error: No JSON output\n" .. out.stdout)
								return
							end

							---@alias JsonDiagnostic {message: string, severity: string, line: number}
							local input = reversed:sub(start, finish):reverse()

							---@type boolean,JsonDiagnostic[]
							local ok, diagnostics = pcall(vim.json.decode, input)
							if not ok then
								vim.notify("Error Parsing JSON: " .. diagnostics .. "\nInput:\n" .. input)
								return
							end

							local diagnostic_data = {}

							for _, diagnostic in ipairs(diagnostics) do
								table.insert(diagnostic_data,
									lint_data(buffer, diagnostic.line - 1, diagnostic.severity, diagnostic.message)
								)
							end

							vim.diagnostic.set(namespace, buffer, diagnostic_data)
						end)
					else
						vim.schedule(function()
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(out.stderr, "\n"))
							vim.notify("Error ai linter: " .. out.stderr)
						end)
					end
				end)
			end, { desc = "Run Code AI Linter" })

			vim.keymap.set('n', '<leader>cg', function()
				local buffer = vim.api.nvim_get_current_buf()
				local filename = vim.api.nvim_buf_get_name(buffer)

				local prompt = "I'm working on this file: " .. filename ..
					"\n\nI'm purposely using non existent function/method calls. " ..
					"Your job is to create the missing files with the missing implementations " ..
					"of the functions/methods which then I can import, do not modify my file, since I'm working on it." ..
					"\n\nWork smart, and in parallel, also create tests for the missing functions/methods. " ..
					"So that I can run the tests and verify that everything is working as expected. " ..
					"If you require any libraries, add comments to the code to explain why you need them. " ..
					"\n\nREMEMBER: DO NOT MODIFY ANY EXISTING FILES, ONLY CREATE NEW FILES AND COMMENT HOW TO IMPORT THEM."


				local command = {
					"stdbuf", "-oL",
					"opencode", "run",
					"--agent", "build",
					"--thinking", prompt
				}

				vim.notify("Saving file! AI lsp generator is cooking...")
				vim.cmd.write()

				local bufnr = vim.api.nvim_create_buf(true, true)
				vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
				vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
				vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })

				vim.api.nvim_buf_set_name(bufnr, "AI API Generator " .. bufnr)
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(table.concat(command, "\n"), "\n"))

				vim.system(command, {
					text = true,
					on_stdout = function(err, data)
						if data then
							vim.schedule(function()
								local lines = vim.split(data, "[\r\n]+")
								if #lines > 0 and lines[1] == "" then table.remove(lines, 1) end

								vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)

								local win = vim.fn.bufwinid(bufnr)
								if win ~= -1 then
									vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(bufnr), 0 })
								end
							end)
						end
					end,
				}, function(out)
					if out.code == 0 then
						vim.schedule(function()
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(out.stdout, "\n"))
						end)
					else
						vim.schedule(function()
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(out.stderr, "\n"))
						end)
					end
				end)
			end, { desc = "Run Code Missing API Generator" })
		end
	},
	{
		"nickjvandyke/opencode.nvim",
		version = "*", -- Latest stable release
		dependencies = {
			{
				-- `snacks.nvim` integration is recommended, but optional
				---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
				"folke/snacks.nvim",
				optional = true,
				opts = {
					input = {}, -- Enhances `ask()`
					picker = { -- Enhances `select()`
						actions = {
							opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
						},
						win = {
							input = {
								keys = {
									["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
								},
							},
						},
					},
				},
			},
		},
		config = function()
			---@type opencode.Opts
			vim.g.opencode_opts = {
				-- Your configuration, if any; goto definition on the type or field for details
			}

			vim.o.autoread = true -- Required for `opts.events.reload`

			-- Recommended/example keymaps
			vim.keymap.set({ "n", "x" }, "<leader>ca",
				function() require("opencode").ask("@this: ", { submit = true }) end,
				{ desc = "Ask opencode…" })
			vim.keymap.set({ "n", "x" }, "<leader>cx", function() require("opencode").select() end,
				{ desc = "Execute opencode action…" })
			vim.keymap.set({ "n", "t" }, "<leader>ct", function() require("opencode").toggle() end,
				{ desc = "Toggle opencode" })

			vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
				{ desc = "Add range to opencode", expr = true })
			vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end,
				{ desc = "Add line to opencode", expr = true })

			vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
				{ desc = "Scroll opencode up" })
			vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
				{ desc = "Scroll opencode down" })

			-- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap)
			-- vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
			-- vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
		end,
	}
}

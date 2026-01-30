---@param dir string
---@return string?
local function findNewestFile(dir)
	local newest_file = nil
	local newest_time = 0

	for file in vim.fs.dir(dir) do
		local full_path = dir .. "/" .. file
		local stat = vim.uv.fs_stat(full_path)

		if stat and stat.type == "file" and stat.mtime.sec > newest_time then
			newest_time = stat.mtime.sec
			newest_file = full_path
		end
	end

	return newest_file
end

---@type string?
local file = ""

return {
	{
		"ThePrimeagen/99",
		config = function()
			local _99 = require("99")

			-- For logging that is to a file if you wish to trace through requests
			-- for reporting bugs, i would not rely on this, but instead the provided
			-- logging mechanisms within 99.  This is for more debugging purposes
			local cwd = vim.uv.cwd()
			local basename = vim.fs.basename(cwd)
			_99.setup({
				model = "opencode/big-pickle",

				logger = {
					level = _99.DEBUG,
					path = "/tmp/" .. basename .. ".99.debug",
					print_on_error = true,
				},

				--- A new feature that is centered around tags
				completion = {
					--- Defaults to .cursor/rules
					-- I am going to disable these until i understand the
					-- problem better.  Inside of cursor rules there is also
					-- application rules, which means i need to apply these
					-- differently
					-- cursor_rules = "<custom path to cursor rules>"

					--- A list of folders where you have your own SKILL.md
					--- Expected format:
					--- /path/to/dir/<skill_name>/SKILL.md
					---
					--- Example:
					--- Input Path:
					--- "scratch/custom_rules/"
					---
					--- Output Rules:
					--- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
					--- ... the other rules in that dir ...
					---
					custom_rules = { "scratch/custom_rules/" },

					--- What autocomplete do you use.  We currently only
					--- support cmp right now
					source = "cmp",
				}

				--- WARNING: if you change cwd then this is likely broken
				--- ill likely fix this in a later change
				---
				--- md_files is a list of files to look for and auto add based on the location
				--- of the originating request.  That means if you are at /foo/bar/baz.lua
				--- the system will automagically look for:
				--- /foo/bar/AGENT.md
				--- /foo/AGENT.md
				--- assuming that /foo is project root (based on cwd)
				-- md_files = { "AGENT.md" },
			})

			-- Create your own short cuts for the different types of actions
			vim.keymap.set("n", "<leader>cf", function() _99.fill_in_function() end, { desc = "Fill in function" })
			vim.keymap.set("n", "<leader>cc", function() _99.fill_in_function_prompt() end, { desc = "Fill in function" })
			vim.keymap.set("n", "<leader>cp",
				function()
					local latest = findNewestFile("./tmp")
					if latest and latest ~= file then
						vim.cmd("r " .. latest)
						file = latest
						return
					end
					print("No new file")
				end,
				{ desc = "Pastes the latest prompt output" }
			)

			-- take extra note that i have visual selection only in v mode
			-- technically whatever your last visual selection is, will be used
			-- so i have this set to visual mode so i dont screw up and use an
			-- old visual selection
			--
			-- likely ill add a mode check and assert on required visual mode
			-- so just prepare for it now
			vim.keymap.set("v", "<leader>cf", function() _99.visual() end, { desc = "Visual fill" })
			vim.keymap.set("v", "<leader>cc", function() _99.visual_prompt({}) end, { desc = "Visual prompt" })

			--- if you have a request you dont want to make any changes, just cancel it
			vim.keymap.set("n", "<leader>cz", function() _99.stop_all_requests() end, { desc = "Cancel request" })
			vim.keymap.set("v", "<leader>cz", function() _99.stop_all_requests() end, { desc = "Cancel request" })

			--- Example: Using rules + actions for custom behaviors
			--- Create a rule file like ~/.rules/debug.md that defines custom behavior.
			--- For instance, a "debug" rule could automatically add printf statements
			--- throughout a function to help debug its execution flow.
			vim.keymap.set("n", "<leader>cd",
				function() _99.fill_in_function({}) end,
				{ desc = "Fill in function debug" }
			)
		end,
	},
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
}

return {
	{
		dir = vim.fn.stdpath("config") .. "/lua/opencode-mm",
		name = "opencode-mm",
		lazy = true,
		cmd = { "OpenCode" },
		keys = {
			{
				"<leader>oc",
				function()
					require("opencode-mm").toggle()
				end,
				desc = "Toggle OpenCode"
			},
			{
				"<leader>on",
				function()
					require("opencode-mm").new_session()
				end,
				desc = "New OpenCode session"
			},
			{
				"<leader>os",
				function()
					require("opencode-mm").select_session()
				end,
				desc = "Select OpenCode session"
			},
			{
				"<leader>ov",
				function()
					require("opencode-mm").send_selection()
				end,
				mode = "x",
				desc = "Send selection to OpenCode"
			},
			{
				"<leader>ca",
				function()
					require("opencode-mm").ask()
				end,
				mode = { "n", "x" },
				desc = "Ask OpenCode about this"
			},
			{
				"<leader>cx",
				function()
					require("opencode-mm").execute()
				end,
				mode = { "n", "x" },
				desc = "OpenCode action for this"
			},
			{
				"<leader>cm",
				function()
					require("opencode-mm").select_model()
				end,
				mode = "n",
				desc = "OpenCode model picker"
			},
		},
		config = function()
			require("opencode-mm").setup(vim.g.opencode_mm_opts or {})
		end,
	},
}

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
		},
		config = function()
			require("opencode-mm").setup(vim.g.opencode_mm_opts or {})
		end,
	},
}

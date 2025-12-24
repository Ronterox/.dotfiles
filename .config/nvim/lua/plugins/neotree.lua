return {
	-- {
	-- 	"nvim-neo-tree/neo-tree.nvim",
	-- 	branch = "v3.x",
	-- 	keys = { { '<leader>m', '<Cmd>Neotree toggle current<CR>', mode = { 'n' }, desc = "NvimTreeToggle" } },
	-- 	-- opts = { filesystem = { hijack_netrw_behavior = "open_current" } },
	-- 	cmd = { 'Neotree' },
	-- 	dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
	-- },
	{
		"sphamba/smear-cursor.nvim",
		opts = {                         -- Default  Range
			stiffness = 1.0,             -- 0.6      [0, 1]
			trailing_stiffness = 0.85,   -- 0.45     [0, 1]
			stiffness_insert_mode = 1.0, -- 0.5      [0, 1]
			trailing_stiffness_insert_mode = 1.0, -- 0.5      [0, 1]
			damping = 1.0,               -- 0.85     [0, 1]
			damping_insert_mode = 1.0,   -- 0.9      [0, 1]
			distance_stop_animating = 0.5, -- 0.1      > 0
		},
	},
	{
		'stevearc/oil.nvim',
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			columns = {
				"icon",
				"permissions",
				"type",
				"size",
				"mtime",
			},
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
			}
		},
		-- Optional dependencies
		keys = { { '<leader>m', '<Cmd>Oil<CR>', mode = { 'n' }, desc = "Oil File Explorer" } },
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
	}
}

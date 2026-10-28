-- aic: AI compiler (review a coding Claude while it works).
-- Keys live under <leader>z (<leader>a is harpoon). `:Aic` opens the aic tab.
return {
	dir = vim.fn.expand("~/Documents/Projects/AIProjects/HarnessTools/aic/nvim"),
	name = "aic",
	lazy = false, -- cheap at startup: commands only, activates inside projects with .aic/
	config = function()
		require("aic").setup({})
	end,
}

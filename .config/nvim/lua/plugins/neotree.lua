return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    keys = { { '<leader>m', '<Cmd>Neotree toggle current<CR>', mode = { 'n' }, desc = "NvimTreeToggle" } },
    opts = { filesystem = { hijack_netrw_behavior = "open_current" } },
    cmd = { 'Neotree' },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
}

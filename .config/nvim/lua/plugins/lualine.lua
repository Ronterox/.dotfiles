-- function harpoonFiles()
--     if vim.api.nvim_buf_get_option(0, 'buftype') ~= '' then return '' end
--     local tabela = require("harpoon").get_mark_config()['marks']
--     local currentFile = vim.fn.split(vim.api.nvim_buf_get_name(0), "/")
--     currentFile = currentFile[#currentFile]
--     local ret = {}
--     local shorcuts = { 'h', 'j', 'k', 'l' }
--     for key, value in pairs(tabela) do
--         local file = vim.fn.split(value['filename'], "/")
--         file = file[#file]
--         file = file == currentFile and file .. "*" or file .. " "
--         key = shorcuts[key] or key
--         table.insert(ret, "  [" .. key .. "] " .. file)
--     end
--     return table.concat(ret)
-- end

return {
    {
        'nvim-lualine/lualine.nvim',
        event = "VeryLazy",
        opts = {
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { 'buffers', require('lsp-progress').progress },
                lualine_x = { 'encoding', 'fileformat', 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = { 'location' }
            },
            dependencies = { 'nvim-tree/nvim-web-devicons', 'linrongbin16/lsp-progress.nvim' },
        },
        config = function(_, opts)
            local custom_theme = require('lualine.themes.vscode')
            custom_theme.normal.a.bg = '#5674D6'
            custom_theme.insert.a.bg = '#E3BC5B'
            custom_theme.insert.y = { fg = '#E3BC5B' }
            custom_theme.visual.a.bg = '#569cd6'
            custom_theme.visual.y = { fg = '#569cd6' }
            custom_theme.command.a.bg = '#e46c8e'

            opts.options = { theme = custom_theme }
            require('lualine').setup(opts)
        end
    },
    { 'arkav/lualine-lsp-progress' },
}

return {
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        lazy = true,
        config = false,
        init = function()
            -- Disable automatic setup, we are doing it manually
            vim.g.lsp_zero_extend_cmp = 0
            vim.g.lsp_zero_extend_lspconfig = 0
        end,
    },

    { 'williamboman/mason.nvim', cmd = { 'Mason' }, config = true },

    {
        'L3MON4D3/LuaSnip',
        event = 'InsertEnter',
        dependencies = { 'rafamadriz/friendly-snippets' },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    },

    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = { { 'saadparwaiz1/cmp_luasnip' } },
        config = function()
            -- Here is where you configure the autocompletion settings.
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_cmp()

            -- And you can configure cmp even more, if you want to.
            local cmp = require('cmp')
            local cmp_action = lsp_zero.cmp_action()

            -- Extend the sources, without losing defaults
            local cmp_config = cmp.get_config()
            table.insert(cmp_config.sources, { name = 'luasnip' })
            table.insert(cmp_config.sources, { name = 'sonicpi' })

            cmp.setup({
                formatting = lsp_zero.cmp_format({}),
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                    ['<CR>'] = cmp.mapping.confirm({ select = false })
                }),
                sources = cmp_config.sources,
            })
        end,
    },

    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'williamboman/mason-lspconfig.nvim' },
        },
        config = function()
            -- This is where all the LSP shenanigans will live
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            lsp_zero.on_attach(function(client, bufnr)
                lsp_zero.default_keymaps({ buffer = bufnr, preserve_mappings = false })
                require('sonicpi').lsp_on_init(client, { server_dir = '/opt/sonic-pi/app/server' })
            end)

            lsp_zero.format_on_save({
                format_opts = { async = true, timeout_ms = 5000 },
                servers = {
                    ['pylsp'] = { 'py', 'python' },
                    ['lua_ls'] = { 'lua' },
                    ['clangd'] = { 'c', 'cpp', 'objc', 'objcpp' },
                    ['hls'] = { 'haskell' },
                }
            })

            local nvim_lsp = require('lspconfig')
            nvim_lsp.solargraph.setup {
                settings = {
                    solargraph = {
                        singleFile = true,
                    }
                }
            }
            nvim_lsp.perlpls.setup {}
            nvim_lsp.arduino_language_server.setup {}

            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            nvim_lsp.pylsp.setup({
                capabilities = capabilities,
                settings = {
                    pylsp = {
                        plugins = {
                            ruff = {
                                enabled = true,
                                formatEnabled = true,
                                lineLength = 100,
                            },
                            pycodestyle = {
                                enabled = false,
                                ignore = { 'W391' },
                                maxLineLength = 100
                            }
                        }
                    }
                }
            })

            require('mason-lspconfig').setup({
                automatic_installation = true,
                ensure_installed = {},
                handlers = {
                    lsp_zero.default_setup,
                    lua_ls = function()
                        local lua_opts = lsp_zero.nvim_lua_ls()
                        nvim_lsp.lua_ls.setup(lua_opts)
                    end,
                    hls = function()
                        nvim_lsp.hls.setup({
                            settings = {
                                haskell = {
                                    formattingProvider = 'fourmolu',
                                }
                            }
                        })
                    end,
                    emmet_language_server = function()
                        nvim_lsp.emmet_language_server.setup({
                            filetypes = {
                                'html', 'css', 'javascript',
                                'javascriptreact', 'typescript',
                                'typescriptreact', 'php', 'scss'
                            }
                        })
                    end,
                    htmx = function()
                        nvim_lsp.htmx.setup({
                            filetypes = { 'html', 'php', 'javascript', 'typescript' }
                        })
                    end
                }
            })
        end
    },

    {
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        opts = {},
    },

    -- Pretty Hover
    {
        "Fildo7525/pretty_hover",
        event = "LspAttach",
        opts = {}
    },
}

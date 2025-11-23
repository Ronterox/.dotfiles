return {
	{
		"folke/lazydev.nvim",
		enabled = true,
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library",    words = { "vim%.uv" } },
				{ path = "${3rd}/love2d/library", words = { "love%." } },
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

			vim.lsp.config('solargraph', {
				settings = {
					solargraph = {
						singleFile = true,
					},
				},
			})

			vim.lsp.enable('perlpls')

			vim.lsp.config('vtsls', {
				settings = {
					vtsls = {
						tsserver = {
							globalPlugins = {
								{
									name = '@vue/typescript-plugin',
									location = vim.fn.stdpath 'data' ..
										'/mason/packages/vue-language-server/node_modules/@vue/language-server',
									languages = { 'vue' },
									configNamespace = 'typescript',
								}
							},
						},
					},
				},
				filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
			})

			vim.lsp.config('vue_ls', {
				settings = {
					init_options = {
						typescript = {
							tsdk = '',
						},
					},
				},
			})

			vim.lsp.enable('vtsls')
			vim.lsp.enable('vue_ls')

			vim.lsp.config('pylsp', {
				on_attach = function(client, bufnr)
					-- Disable hover hints
					client.server_capabilities.hoverProvider = false
				end,
				capabilities = require('cmp_nvim_lsp').default_capabilities(),
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

			vim.lsp.config('pyright', {
				on_attach = function(client, bufnr)
					-- Disable Pyright's autocompletion
					-- client.server_capabilities.completionProvider = true

					-- Disable "go to" features
					client.server_capabilities.definitionProvider = false
					client.server_capabilities.referencesProvider = false
					client.server_capabilities.implementationProvider = false
					client.server_capabilities.typeDefinitionProvider = false
					client.server_capabilities.declarationProvider = false
				end,
			})

			vim.lsp.config('emmet_language_server', {
				filetypes = { 'html', 'css', 'php', 'blade' },
			})

			require('mason-lspconfig').setup({ ensure_installed = {} })
		end
	},

	{
		'stevearc/conform.nvim',
		opts = {
			formatters_by_ft = {
				blade = { 'blade-formatter' },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 5000,
				lsp_format = "fallback",
			},
		},
	},

	{
		'ricardoramirezr/blade-nav.nvim',
		dependencies = { 'hrsh7th/nvim-cmp' },
		ft = { 'blade', 'php' },
		opts = { close_tag_on_complete = true },
	},

	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
	},
}

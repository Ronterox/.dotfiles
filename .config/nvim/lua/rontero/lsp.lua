vim.lsp.config('pinescript', {
	cmd = { 'pinescript-lsp', '--stdio' },
	filetypes = { 'pinescript' },
	root_markers = { '.git' },
})

vim.lsp.enable('pinescript')

-- Godot Config
-- /usr/local/bin/nvim
-- --server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line}+1,{col})<CR>"

local cwd = vim.fn.getcwd()
local godot_project_path = ''
for _, value in pairs({ '/', '/../' }) do
	if vim.uv.fs_stat(cwd .. value .. 'project.godot') then
		godot_project_path = cwd .. value
		break
	end
end

if godot_project_path ~= '' and not vim.uv.fs_stat(godot_project_path .. '/server.pipe') then
	vim.fn.serverstart(godot_project_path .. '/server.pipe')
	vim.lsp.config('gdscript', {})
	vim.lsp.enable('gdscript')
end

require('lsp.lsp_hover').setup()

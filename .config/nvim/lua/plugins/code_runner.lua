return {
    'CRAG666/code_runner.nvim',
    keys = {
        { '<C-M-n>', vim.cmd.RunCode,  mode = { 'n' }, desc = "Run code" },
        { '<C-M-m>', vim.cmd.RunClose, mode = { 'n' }, desc = "Run code and close" }
    },
    opts = {
        filetype = {
            typescript = 'bun $dir/$fileName',
            javascript = 'bun $dir/$fileName',
            r = 'Rscript $dir/$fileName',
            go = 'go run $dir/$fileName',
            rust = 'cargo run $dir/$fileName || cargo run --bin $fileNameWithoutExt'
        }
    }
}

return {
    'CRAG666/code_runner.nvim',
    keys = {
        { '<C-M-n>', vim.cmd.RunCode,  mode = { 'n' }, desc = "Run code" },
        { '<C-M-m>', vim.cmd.RunClose, mode = { 'n' }, desc = "Run code and close" }
    },
    opts = {
        filetype = {
            -- java = {"cd $dir &&", "javac $fileName &&", "java $fileNameWithoutExt"},
            typescript = 'bun $fileName',
            javascript = 'bun $fileName',
            r = 'Rscript $fileName'
            -- rust = {"cd $dir &&", "rustc $fileName &&", "$dir/$fileNameWithoutExt"}
        }
    }
}

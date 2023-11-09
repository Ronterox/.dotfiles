return {
    'kevinhwang91/nvim-ufo',
    dependencies = 'kevinhwang91/promise-async',
    keys = {
        { 'zR', ':lua require("ufo").openAllFolds()<CR>',  mode = { 'n' }, desc = "Open All Folds Ufo" },
        { 'zM', ':lua require("ufo").closeAllFolds()<CR>', mode = { 'n' }, desc = "Close All Folds Ufo" },
    },
    config = function() require('ufo').setup() end
}

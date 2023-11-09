return {
    -- copilot
    {
        "github/copilot.vim",
        event = { 'BufRead', 'BufNewFile' },
        cmd = 'Copilot',
        build = ':Copilot setup'
    },
}


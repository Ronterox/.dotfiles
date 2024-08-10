return {
    'github/copilot.vim',
    enabled = false,
    event = { 'BufEnter' },
    cmd = 'Copilot',
    build = ':Copilot setup',
}
